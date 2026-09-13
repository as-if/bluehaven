from google.cloud import firestore

db = firestore.Client(project='bluehaven-automation')
docs = db.collection('bookings').where('guestName', '==', 'Raeefa').stream()
for doc in docs:
    print(f"--- BOOKING: {doc.id} ---")
    data = doc.to_dict()
    print("rooms:", data.get('rooms'))
    print("meta:", data.get('meta'))
    print("adults:", data.get('adults'))
    print("children:", data.get('children'))
