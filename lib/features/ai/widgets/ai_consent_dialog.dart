import 'package:flutter/material.dart';

class AiConsentDialog extends StatelessWidget {
  const AiConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Data Processing Consent'),
      content: const SingleChildScrollView(
        child: Text(
          'We use third-party AI services to provide features such as skin analysis and personalized recommendations. '
          'To use these features, some of your data may be securely sent to our AI service provider(s), including OpenAI, such as:\n'
          '- photos you upload for skin analysis\n'
          '- messages you send to the AI assistant\n'
          '- relevant profile details needed to generate results\n\n'
          'Your data is used only to provide these features. It is not sold for advertising.\n\n'
          'By tapping "I Agree," you consent to sending this data to our third-party AI service provider(s), including OpenAI, for processing.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I Agree'),
        ),
      ],
    );
  }
}
