import 'dart:convert';
import 'package:http/http.dart' as http;

class AIResponse {
  final String text;
  final bool shouldEscalateToHuman;
  final String? escalationReason;
  final List<String> sources;

  const AIResponse({
    required this.text,
    this.shouldEscalateToHuman = false,
    this.escalationReason,
    this.sources = const [],
  });
}

abstract class AIProvider {
  String get name;
  Future<AIResponse> generateResponse({
    required String prompt,
    required String knowledgeBaseContext,
    List<Map<String, String>> history = const [],
  });
}

/// Cloud LLM Provider (DeepSeek / Gemini API via Cloud Functions or Direct)
class CloudAIProvider implements AIProvider {
  final String apiKey;
  final String endpoint;

  CloudAIProvider({
    this.apiKey = '',
    this.endpoint = 'https://api.deepseek.com/chat/completions',
  });

  @override
  String get name => 'Cloud AI Provider';

  @override
  Future<AIResponse> generateResponse({
    required String prompt,
    required String knowledgeBaseContext,
    List<Map<String, String>> history = const [],
  }) async {
    // Check for hard escalation triggers
    final cleanPrompt = prompt.toLowerCase();
    if (cleanPrompt.contains('refund') ||
        cleanPrompt.contains('discount') ||
        cleanPrompt.contains('price') ||
        cleanPrompt.contains('money') ||
        cleanPrompt.contains('cancel') ||
        cleanPrompt.contains('complaint') ||
        cleanPrompt.contains('hurt') ||
        cleanPrompt.contains('hospital') ||
        cleanPrompt.contains('doctor') ||
        cleanPrompt.contains('emergency')) {
      return const AIResponse(
        text: 'This matter requires immediate host assistance. Connecting you with our team...',
        shouldEscalateToHuman: true,
        escalationReason: 'Policy / Safety / Financial Escalation',
      );
    }

    if (apiKey.isEmpty) {
      return AIResponse(
        text: 'I can help answer questions from our island knowledge base.',
        shouldEscalateToHuman: false,
        sources: ['Local Knowledge Base'],
      );
    }

    try {
      final messages = [
        {
          'role': 'system',
          'content': 'You are the AI Concierge for Blue Haven guesthouse in Thulusdhoo, Maldives. '
              'Ground your answers STRICTLY on the knowledge base below. '
              'If the information is not in the knowledge base, politely state that you do not know and suggest speaking to the team. '
              'Never invent policy.\n\n'
              'Knowledge Base:\n$knowledgeBaseContext',
        },
        ...history,
        {'role': 'user', 'content': prompt},
      ];

      final res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        return AIResponse(text: content, sources: ['Knowledge Base']);
      }
    } catch (_) {
      // Degrade gracefully
    }

    return const AIResponse(
      text: 'I could not reach the cloud concierge service. Let me connect you directly with our front desk.',
      shouldEscalateToHuman: true,
      escalationReason: 'Network timeout',
    );
  }
}

/// Local LAN Ollama Provider (for zero-internet high-speed inference on property mini-PC)
class OllamaLANProvider implements AIProvider {
  final String lanBaseUrl; // e.g. http://192.168.1.100:11434
  final String model;

  OllamaLANProvider({
    this.lanBaseUrl = 'http://192.168.1.50:11434',
    this.model = 'llama3.2',
  });

  @override
  String get name => 'LAN Ollama Provider';

  @override
  Future<AIResponse> generateResponse({
    required String prompt,
    required String knowledgeBaseContext,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$lanBaseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': 'Context: $knowledgeBaseContext\n\nQuestion: $prompt',
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AIResponse(text: data['response'] ?? '', sources: ['LAN AI']);
      }
    } catch (_) {}

    return const AIResponse(
      text: 'LAN AI unavailable. Escalating to human desk...',
      shouldEscalateToHuman: true,
    );
  }
}
