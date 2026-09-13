const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotification = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      const snap = event.data;
      if (!snap) {
        return null;
      }

      const notification = snap.data();
      const targetUserId = notification.userId;

      const userDoc = await admin.firestore()
          .collection("users")
          .doc(targetUserId)
          .get();

      if (!userDoc.exists) {
        console.log("User not found");
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${targetUserId}`);
        return null;
      }

      const payload = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          referenceId: notification.referenceId || "",
          type: notification.type || "",
        },
        token: fcmToken,
      };

      try {
        const response = await admin.messaging().send(payload);
        console.log("Successfully sent message:", response);
      } catch (error) {
        console.log("Error sending message:", error);
      }

      return null;
    },
);

const {onDocumentWritten} = require("firebase-functions/v2/firestore");

// Listen for any changes in the 'bookings' collection
exports.onBookingUpdate = onDocumentWritten(
    "bookings/{bookingId}",
    async (event) => {
    // 1. Setup
      const snapshot = event.data;
      if (!snapshot) {
        return null; // No data associated with the event
      }

      const before = snapshot.before.data();
      const after = snapshot.after.data();
      const bookingId = event.params.bookingId;
      const db = admin.firestore();

      // 2. Identify the Event Type
      let title = "";
      let body = "";
      let type = "booking";
      let shouldNotify = false;

      const formatDate = (ts) => {
        if (!ts || !ts.toDate) return "N/A";
        return ts.toDate().toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
          year: "numeric",
        });
      };

      // CASE A: New Booking Created (Document didn't exist before)
      if (!before && after) {
        title = "New Booking! 🎉";
        const roomCount = (after.meta && after.meta.room_count) || 1;
        const checkInStr = formatDate(after.check_in);
        const checkOutStr = formatDate(after.check_out);
        body = `New reservation from ${after.channel || "Direct"}: ` +
            `${after.guest_name} (${roomCount} rooms). ` +
            `Dates: ${checkInStr} to ${checkOutStr}.`;
        shouldNotify = true;
      } else if (before && !after) {
      // CASE B: Booking Deleted (Document existed before, but not now)
        title = "Booking Deleted";
        body = `Booking ${bookingId} has been permanently deleted.`;
        shouldNotify = true;
        type = "system";
      } else if (before && after) {
      // CASE C: Booking Updated (Document exists in both)
        // C1: Status Change (e.g., Confirmed -> Cancelled or Checked-In)
        if (before.status !== after.status) {
          title = "Status Update";
          const by = after.last_updated_by;
          const updater = by ? ` (by ${by})` : "";
          body = `${after.guest_name} is now ` +
                 `${after.status.toUpperCase()}${updater}.`;
          shouldNotify = true;

          // Customize for Cancellations
          if (after.status === "cancelled") {
            const checkInStr = formatDate(after.check_in);
            const checkOutStr = formatDate(after.check_out);
            const by = after.last_updated_by;
            const canceller = by ? ` by ${by}` : "";
            title = "Booking Cancelled ❌";
            body = `${after.guest_name} reservation ` +
                   `(${checkInStr} to ${checkOutStr}) ` +
                   `was cancelled${canceller}.`;
          }
        }
        // C2: Modification (Dates or Price)
        const beforeIn = before.check_in;
        const afterIn = after.check_in;
        const beforeOut = before.check_out;
        const afterOut = after.check_out;

        const checkInChanged = beforeIn && afterIn &&
            beforeIn.seconds !== afterIn.seconds;
        const checkOutChanged = beforeOut && afterOut &&
            beforeOut.seconds !== afterOut.seconds;
        const priceChanged = before.total_price !== after.total_price;

        if (!shouldNotify && after.status !== "cancelled" &&
            (checkInChanged || checkOutChanged || priceChanged)) {
          const checkInStr = formatDate(after.check_in);
          const checkOutStr = formatDate(after.check_out);
          const by = after.last_updated_by;
          const updater = by ? ` by ${by}` : "";

          title = "Booking Modified 📅";
          const changes = [];
          if (checkInChanged || checkOutChanged) {
            changes.push(`Dates: ${checkInStr} to ${checkOutStr}`);
          }
          if (priceChanged) {
            const oldP = before.total_price || 0;
            const newP = after.total_price || 0;
            changes.push(`Price: $${oldP} ➔ $${newP}`);
          }

          body = `${after.guest_name} booking was modified${updater}. ` +
                 `${changes.join(", ")}.`;
          shouldNotify = true;
        }
      }

      // 3. Stop if no relevant change detected
      if (!shouldNotify) {
        return null;
      }

      // 4. Dispatch Notifications to Managers & Supervisors
      // We first find who needs to know (Managers and Supervisors)
      const usersSnap = await db.collection("users")
          .where("role", "in", ["manager", "supervisor"])
          .get();

      const batch = db.batch();

      usersSnap.docs.forEach((userDoc) => {
        const notificationRef = db.collection("notifications").doc();
        batch.set(notificationRef, {
          userId: userDoc.id,
          title: title,
          body: body,
          type: type,
          referenceId: bookingId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // 5. Commit the batch write
      return batch.commit();
    });

/**
 * Helper to parse meal times
 * @param {string} mealTime The time string
 * @param {Date} todayStart Start of today
 * @return {Date} The parsed date
 */
function getMealTime(mealTime, todayStart) {
  const clean = mealTime.toLowerCase().trim();
  const year = todayStart.getFullYear();
  const month = todayStart.getMonth();
  const date = todayStart.getDate();

  if (clean.includes("breakfast")) {
    return new Date(year, month, date, 8, 0);
  } else if (clean.includes("lunch")) {
    return new Date(year, month, date, 13, 0);
  } else if (clean.includes("dinner")) {
    return new Date(year, month, date, 19, 0);
  }

  try {
    if (clean.includes("am") || clean.includes("pm")) {
      const parts = clean.split(/[\s:]+/);
      let hour = parseInt(parts[0], 10);
      const minute = parts.length > 1 ? parseInt(parts[1], 10) || 0 : 0;
      if (clean.includes("pm") && hour < 12) hour += 12;
      if (clean.includes("am") && hour === 12) hour = 0;
      return new Date(year, month, date, hour, minute);
    } else {
      const parts = clean.split(":");
      const hour = parseInt(parts[0], 10);
      const minute = parts.length > 1 ? parseInt(parts[1], 10) : 0;
      return new Date(year, month, date, hour, minute);
    }
  } catch (e) {
    return new Date(year, month, date, 10, 0);
  }
}

exports.checkOverdueTasks = onSchedule(
    {
      schedule: "0 12-18 * * *",
      timeZone: "Asia/Seoul",
      memory: "512MiB",
    },
    async (event) => {
      const db = admin.firestore();
      const now = new Date();

      const seoulString = now.toLocaleString("en-US", {
        timeZone: "Asia/Seoul",
      });
      const seoulDate = new Date(seoulString);
      const year = seoulDate.getFullYear();
      const month = seoulDate.getMonth();
      const date = seoulDate.getDate();
      const todayStart = new Date(year, month, date);
      const todayEnd = new Date(year, month, date + 1);

      // Fetch all managers and supervisors
      const usersSnap = await db.collection("users")
          .where("role", "in", ["manager", "supervisor"])
          .get();

      const managerIds = usersSnap.docs.map((doc) => doc.id);
      if (managerIds.length === 0) return null;

      const dispatchNotification = async (refId, title, body) => {
        const existing = await db.collection("notifications")
            .where("referenceId", "==", refId)
            .limit(1)
            .get();

        if (existing.empty) {
          const batch = db.batch();
          managerIds.forEach((managerId) => {
            const notificationRef = db.collection("notifications").doc();
            batch.set(notificationRef, {
              userId: managerId,
              title: title,
              body: body,
              type: "system",
              referenceId: refId,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
          await batch.commit();
          console.log(`Dispatched overdue alert: ${refId}`);
        }
      };

      // 1. Housekeeping tasks check
      const tasksSnap = await db.collection("tasks")
          .where("status", "in", ["pending", "in_progress"])
          .get();

      for (const doc of tasksSnap.docs) {
        const task = doc.data();
        const createdAt = task.created_at ? task.created_at.toDate() : null;
        if (createdAt) {
          const diffMs = now.getTime() - createdAt.getTime();
          const diffHours = diffMs / (1000 * 60 * 60);
          if (diffHours >= 3) {
            const refId = `${doc.id}_overdue`;
            const rId = task.room_id || task.roomId;
            const tType = task.task_type || task.taskType;
            await dispatchNotification(
                refId,
                `Overdue Housekeeping: Room ${rId}`,
                `Housekeeping task "${tType}" for Room ${rId} ` +
                `is still pending after 3 hours.`,
            );
          }
        }
      }

      // 2. Kitchen orders check
      const ordersSnap = await db.collection("orders")
          .where("date", ">=", todayStart)
          .where("date", "<", todayEnd)
          .get();

      for (const doc of ordersSnap.docs) {
        const order = doc.data();
        const cond = !order.is_completed && !order.is_skipping && order.time;
        if (cond) {
          const mealTime = getMealTime(order.time, todayStart);
          const limit = mealTime.getTime() + (3 * 60 * 60 * 1000);
          if (seoulDate.getTime() > limit) {
            const refId = `${doc.id}_overdue`;
            const rId = order.room_id || order.roomId;
            await dispatchNotification(
                refId,
                `Overdue Meal Serving: Room ${rId}`,
                `Meal order (${order.time}) for Room ${rId} ` +
                `remains uncompleted after 3 hours.`,
            );
          }
        }
      }

      // 3. Bookings check (arrivals and departures)
      const past2Days = new Date(todayStart.getTime() - (2 * 24 * 3600 * 1000));

      // Check-ins (confirmed status)
      const checkInsSnap = await db.collection("bookings")
          .where("status", "==", "confirmed")
          .where("check_in", ">=", past2Days)
          .where("check_in", "<", todayEnd)
          .get();

      for (const doc of checkInsSnap.docs) {
        const booking = doc.data();
        const checkInDate = booking.check_in ?
            booking.check_in.toDate() : null;
        if (checkInDate) {
          const expectedCheckIn = new Date(
              checkInDate.getFullYear(),
              checkInDate.getMonth(),
              checkInDate.getDate(),
              14,
              0,
          );
          const limit = expectedCheckIn.getTime() + (3 * 60 * 60 * 1000);
          if (now.getTime() > limit) {
            const refId = `${doc.id}_checkin_overdue`;
            await dispatchNotification(
                refId,
                "Pending Check-In Alert",
                `Guest "${booking.guest_name}" check-in is pending ` +
                `for more than 3 hours since standard time.`,
            );
          }
        }
      }

      // Check-outs (checkedIn status)
      const checkOutsSnap = await db.collection("bookings")
          .where("status", "==", "checkedIn")
          .where("check_out", ">=", past2Days)
          .where("check_out", "<", todayEnd)
          .get();

      for (const doc of checkOutsSnap.docs) {
        const booking = doc.data();
        const checkOutDate = booking.check_out ?
            booking.check_out.toDate() : null;
        if (checkOutDate) {
          const expectedCheckOut = new Date(
              checkOutDate.getFullYear(),
              checkOutDate.getMonth(),
              checkOutDate.getDate(),
              12,
              0,
          );
          const limit = expectedCheckOut.getTime() + (3 * 60 * 60 * 1000);
          if (now.getTime() > limit) {
            const refId = `${doc.id}_checkout_overdue`;
            await dispatchNotification(
                refId,
                "Pending Check-Out Alert",
                `Guest "${booking.guest_name}" check-out is pending ` +
                `for more than 3 hours since standard time.`,
            );
          }
        }
      }

      return null;
    },
);

const {onRequest} = require("firebase-functions/v2/https");
const corsLib = require("cors")({origin: true});
const {GoogleGenAI} = require("@google/generative-ai");

/**
 * Helper to update breakfast in Firestore.
 * @param {string} bookingId The booking reference ID.
 * @param {string} date The date string (YYYY-MM-DD).
 * @param {string} choice The breakfast selection.
 * @return {Promise<object>} Result of the update operation.
 */
async function updateBreakfastInDB(bookingId, date, choice) {
  const db = admin.firestore();
  const docRef = db.collection("bookings").doc(bookingId);
  await docRef.update({
    [`breakfastChoices.${date}`]: choice,
  });
  return {
    success: true,
    message: `Breakfast for ${date} updated to ${choice}`,
  };
}

/**
 * Helper to create service request in Firestore.
 * @param {string} bookingId The booking reference ID.
 * @param {string} requestType Type of request (cleaning, towels, etc).
 * @param {string} description Detail/notes of the request.
 * @return {Promise<object>} Result of the create operation.
 */
async function createServiceRequestInDB(bookingId, requestType, description) {
  const db = admin.firestore();
  await db.collection("serviceRequests").add({
    bookingId,
    requestType,
    description,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {
    success: true,
    message: `Created ${requestType} request successfully`,
  };
}

exports.generateCustomToken = onRequest((req, res) => {
  return corsLib(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).json({error: "Method not allowed"});
    }

    const {bookingId, lastName} = req.body;
    if (!bookingId || !lastName) {
      return res.status(400).json({error: "Missing bookingId or lastName"});
    }

    try {
      const db = admin.firestore();
      const cleanBookingId = bookingId.trim().toUpperCase();
      const cleanLastName = lastName.trim().toLowerCase();

      const bookingDoc = await db.collection("bookings")
          .doc(cleanBookingId).get();
      if (!bookingDoc.exists) {
        return res.status(404).json({error: "Booking not found"});
      }

      const bookingData = bookingDoc.data();
      const guestName = bookingData.guest_name || bookingData.guestName || "";
      const nameParts = guestName.toLowerCase().split(/\s+/);
      const isLastNameMatch = nameParts.includes(cleanLastName) ||
                              bookingData.lastName?.toLowerCase() ===
                              cleanLastName ||
                              guestName.toLowerCase().endsWith(cleanLastName);

      if (!isLastNameMatch) {
        return res.status(401).json({
          error: "Last name does not match the booking record",
        });
      }

      // Generate Firebase custom token
      const customToken = await admin.auth().createCustomToken(cleanBookingId, {
        lastName: cleanLastName,
        role: "guest",
      });

      return res.status(200).json({token: customToken});
    } catch (error) {
      console.error("Error generating custom token:", error);
      return res.status(500).json({error: "Internal server error"});
    }
  });
});

exports.guestChat = onRequest((req, res) => {
  return corsLib(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).json({error: "Method not allowed"});
    }

    const {messages, bookingId, guestName, roomNumber} = req.body;
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({error: "Missing or invalid messages"});
    }

    const lastMessage = messages[messages.length - 1]?.content || "";
    const systemPrompt = `You are the AI Concierge for Blue Haven Retreat, ` +
        `a luxury guesthouse in Thulusdhoo, Maldives. The current guest is ` +
        `${guestName || "Valued Guest"} in Room ${roomNumber || "Pending"}. ` +
        `Booking ID is ${bookingId || "Unknown"}.
    
    Guidelines:
    1. Help guests manage their stay (breakfast choices, service requests).
    2. Island info: Wi-Fi: escape2paradise, Cokes and Chickens surf breaks, ` +
        `desalinated Coca-Cola plant, modest village dress code, bikini beach.
    3. Rules: no alcohol on local islands, modesty, no pets allowed.
    
    If the guest requests changes to breakfast or logs housekeeping/towel/` +
        `maintenance/excursion requests, USE the function tools. Always ` +
        `trigger the function so the database updates.`;

    const useDeepSeek = !!process.env.DEEPSEEK_API_KEY;

    if (useDeepSeek) {
      // ── DEEPSEEK IMPLEMENTATION ──────────────────────────────────────────
      try {
        const deepseekKey = process.env.DEEPSEEK_API_KEY;
        const deepseekMessages = [
          {role: "system", content: systemPrompt},
          ...messages.map((m) => ({role: m.role, content: m.content})),
        ];

        const tools = [
          {
            type: "function",
            function: {
              name: "updateBreakfastSelection",
              description: "Updates the breakfast selection for a " +
                           "specific date (Continental or Maldivian).",
              parameters: {
                type: "object",
                properties: {
                  bookingId: {
                    type: "string",
                    description: "The guest's booking ID reference.",
                  },
                  date: {
                    type: "string",
                    description: "The stay date (format YYYY-MM-DD).",
                  },
                  choice: {
                    type: "string",
                    enum: ["Continental", "Maldivian"],
                    description: "The choice of breakfast.",
                  },
                },
                required: ["bookingId", "date", "choice"],
              },
            },
          },
          {
            type: "function",
            function: {
              name: "requestHousekeepingService",
              description: "Logs a guest request for cleaning, towels/" +
                           "toiletries, maintenance, or activity bookings.",
              parameters: {
                type: "object",
                properties: {
                  bookingId: {type: "string"},
                  requestType: {
                    type: "string",
                    enum: ["cleaning", "towels", "maintenance", "activity"],
                  },
                  description: {
                    type: "string",
                    description: "Specific details of the request.",
                  },
                },
                required: ["bookingId", "requestType", "description"],
              },
            },
          },
        ];

        const response = await fetch("https://api.deepseek.com/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${deepseekKey}`,
          },
          body: JSON.stringify({
            model: "deepseek-chat",
            messages: deepseekMessages,
            tools: tools,
          }),
        });

        const data = await response.json();
        const choice = data.choices?.[0];
        const toolCalls = choice?.message?.tool_calls;

        if (toolCalls && toolCalls.length > 0) {
          const actionsTaken = [];
          for (const tc of toolCalls) {
            const args = JSON.parse(tc.function.arguments);
            let actionResult;

            if (tc.function.name === "updateBreakfastSelection") {
              actionResult = await updateBreakfastInDB(
                  args.bookingId, args.date, args.choice);
              actionsTaken.push({type: "update_breakfast", ...args});
            } else if (tc.function.name === "requestHousekeepingService") {
              actionResult = await createServiceRequestInDB(
                  args.bookingId, args.requestType, args.description);
              actionsTaken.push({type: "service_request", ...args});
            }

            // Feed tool result back to DeepSeek
            deepseekMessages.push(choice.message);
            deepseekMessages.push({
              role: "tool",
              tool_call_id: tc.id,
              content: JSON.stringify(actionResult),
            });
          }

          // Fetch final model message
          const finalResponse = await fetch(
              "https://api.deepseek.com/chat/completions",
              {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": `Bearer ${deepseekKey}`,
                },
                body: JSON.stringify({
                  model: "deepseek-chat",
                  messages: deepseekMessages,
                }),
              },
          );
          const finalData = await finalResponse.json();
          return res.status(200).json({
            reply: finalData.choices?.[0]?.message?.content ||
                   "Action processed successfully.",
            actionsTaken,
          });
        }

        return res.status(200).json({
          reply: choice?.message?.content || "How can I help you?",
          actionsTaken: [],
        });
      } catch (err) {
        console.error("DeepSeek API error:", err);
        return res.status(500).json({error: "DeepSeek chat error"});
      }
    } else {
      // ── GEMINI IMPLEMENTATION (DEFAULT) ───────────────────────────────────
      try {
        const geminiKey = process.env.GEMINI_API_KEY;
        if (!geminiKey) {
          return res.status(500).json({
            error: "Gemini API key is not configured",
          });
        }

        const ai = new GoogleGenAI({apiKey: geminiKey});

        // Define tool declarations
        const updateBreakfastSelection = {
          name: "updateBreakfastSelection",
          description: "Updates the breakfast selection for a " +
                       "specific date (Continental or Maldivian).",
          parameters: {
            type: "OBJECT",
            properties: {
              bookingId: {
                type: "STRING",
                description: "The guest's booking ID reference.",
              },
              date: {
                type: "STRING",
                description: "The stay date (format YYYY-MM-DD).",
              },
              choice: {
                type: "STRING",
                description: "The choice of breakfast " +
                            "(Continental or Maldivian).",
              },
            },
            required: ["bookingId", "date", "choice"],
          },
        };

        const requestHousekeepingService = {
          name: "requestHousekeepingService",
          description: "Logs a guest request for cleaning, towels/" +
                       "toiletries, maintenance, or activity bookings.",
          parameters: {
            type: "OBJECT",
            properties: {
              bookingId: {type: "STRING"},
              requestType: {
                type: "STRING",
                description: "Choice of: cleaning, towels, " +
                            "maintenance, activity",
              },
              description: {
                type: "STRING",
                description: "Specific details of the request.",
              },
            },
            required: ["bookingId", "requestType", "description"],
          },
        };

        const model = ai.getGenerativeModel({
          model: "gemini-1.5-flash",
          systemInstruction: systemPrompt,
          tools: [{
            functionDeclarations: [
              updateBreakfastSelection,
              requestHousekeepingService,
            ],
          }],
        });

        // Adapt message format for Gemini
        // User messages are 'user', Model messages are 'model' (or assistant)
        const chatSession = model.startChat({
          history: messages.slice(0, -1).map((m) => ({
            role: m.role === "assistant" ? "model" : "user",
            parts: [{text: m.content}],
          })),
        });

        const result = await chatSession.sendMessage(lastMessage);
        const functionCalls = result.response.functionCalls;

        if (functionCalls && functionCalls.length > 0) {
          const actionsTaken = [];
          const functionResponses = [];

          for (const fc of functionCalls) {
            const args = fc.args;
            let actionResult;

            if (fc.name === "updateBreakfastSelection") {
              actionResult = await updateBreakfastInDB(
                  args.bookingId, args.date, args.choice);
              actionsTaken.push({type: "update_breakfast", ...args});
            } else if (fc.name === "requestHousekeepingService") {
              actionResult = await createServiceRequestInDB(
                  args.bookingId, args.requestType, args.description);
              actionsTaken.push({type: "service_request", ...args});
            }

            functionResponses.push({
              response: actionResult,
            });
          }

          // Send the function responses back to Gemini
          // to get the final text response
          const finalResult = await chatSession.sendMessage(functionResponses);
          return res.status(200).json({
            reply: finalResult.response.text(),
            actionsTaken,
          });
        }

        return res.status(200).json({
          reply: result.response.text(),
          actionsTaken: [],
        });
      } catch (err) {
        console.error("Gemini API error:", err);
        return res.status(500).json({error: "Gemini chat error"});
      }
    }
  });
});

exports.waterTankWebhook = onRequest(async (req, res) => {
  // Extract parameters from query or body
  const level = parseFloat(req.query.level || req.body.level || "0");
  const volume = parseFloat(req.query.volume || req.body.volume || "0");
  const pumpOn = (req.query.pump || req.body.pump) === "1";

  if (level === 0 && volume === 0) {
    return res.status(200).send("Ignored initial/empty data.");
  }

  // Determine current alert level
  let currentAlertLevel = "normal";
  if (level <= 30.0) {
    currentAlertLevel = "critical";
  } else if (level <= 50.0) {
    currentAlertLevel = "low";
  } else if (level >= 130.0) {
    currentAlertLevel = "full";
  }

  const db = admin.firestore();
  const stateRef = db.collection("system_status").doc("water_tank_alert_state");

  try {
    await db.runTransaction(async (transaction) => {
      const stateDoc = await transaction.get(stateRef);
      const stateData = stateDoc.exists ? stateDoc.data() : {};

      const lastAlertLevel = stateData.lastAlertLevel || "normal";
      const lastNotificationTime = stateData.lastNotificationTime ? stateData.lastNotificationTime.toDate() : null;
      const prevPumpOn = stateData.pumpOn || false;

      let notifTitle = null;
      let notifBody = null;
      const now = new Date();
      const isNewAlertLevel = currentAlertLevel !== lastAlertLevel;

      const cooldownExpired = !lastNotificationTime ||
        ((now - lastNotificationTime) > 15 * 60 * 1000);

      if ((isNewAlertLevel || cooldownExpired) && currentAlertLevel !== "normal") {
        if (currentAlertLevel === "critical") {
          notifTitle = "🚨 Critical Water Tank Alert";
          notifBody = `Water level is critically low (${level.toFixed(1)} cm / ${volume.toFixed(0)} L)! Please check the pump.`;
        } else if (currentAlertLevel === "low") {
          notifTitle = "⚠️ Low Water Tank Alert";
          notifBody = `Water level is low (${level.toFixed(1)} cm / ${volume.toFixed(0)} L).`;
        } else if (currentAlertLevel === "full") {
          notifTitle = "🚰 Water Tank Full";
          notifBody = `Water tank is almost full (${level.toFixed(1)} cm / ${volume.toFixed(0)} L).`;
        }
      } else if (pumpOn !== prevPumpOn) {
        if (pumpOn) {
          notifTitle = "⚡ Water Pump Turned ON";
          notifBody = `The water pump has started. Current level: ${level.toFixed(1)} cm.`;
        } else {
          notifTitle = "🛑 Water Pump Turned OFF";
          notifBody = `The water pump has stopped. Current level: ${level.toFixed(1)} cm.`;
        }
      }

      // Query users before any writes
      let usersSnapshot = null;
      if (notifTitle && notifBody) {
        const targetRoles = ["manager", "admin", "staff"];
        const lowerRoles = targetRoles.map((r) => r.toLowerCase());
        const upperRoles = targetRoles.map((r) => r[0].toUpperCase() + r.substring(1));
        const combinedRoles = [...lowerRoles, ...upperRoles];
        const query = db.collection("users").where("role", "in", combinedRoles);
        usersSnapshot = await transaction.get(query);
      }

      // Perform writes
      if (notifTitle && notifBody) {
        transaction.set(stateRef, {
          lastAlertLevel: currentAlertLevel,
          lastNotificationTime: admin.firestore.FieldValue.serverTimestamp(),
          pumpOn: pumpOn,
          level: level,
          volume: volume,
        });

        if (usersSnapshot && !usersSnapshot.empty) {
          const notificationsRef = db.collection("notifications");
          usersSnapshot.forEach((doc) => {
            const newNotifRef = notificationsRef.doc();
            transaction.set(newNotifRef, {
              userId: doc.id,
              title: notifTitle,
              body: notifBody,
              type: "water_tank_alert",
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
        }
      } else {
        transaction.set(stateRef, {
          lastAlertLevel: lastAlertLevel,
          lastNotificationTime: stateData.lastNotificationTime || null,
          pumpOn: pumpOn,
          level: level,
          volume: volume,
        });
      }
    });

    return res.status(200).send("Success");
  } catch (error) {
    console.error("Error in waterTankWebhook:", error);
    return res.status(500).send("Internal Server Error");
  }
});


