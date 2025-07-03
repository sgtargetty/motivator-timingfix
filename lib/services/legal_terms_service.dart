// lib/services/legal_terms_service.dart
class LegalTermsService {
  
  /// Generate comprehensive terms of service
  static String getTermsOfService() {
    return '''
MOTIVATOR AI - TERMS OF SERVICE

Last Updated: ${DateTime.now().toString().split(' ')[0]}

═══════════════════════════════════════════

1. ACCEPTANCE OF TERMS

By using Motivator AI ("the App"), you agree to these Terms of Service. 
If you do not agree, do not use the App.

═══════════════════════════════════════════

2. MOTIVATOR AI RESPONSIBILITIES

WE PROVIDE:
✅ Local app functionality on your device
✅ User interface and experience design
✅ Connection to third-party APIs (with your consent)
✅ Privacy controls and data management tools
✅ Customer support for app-related issues

WE DO NOT:
❌ Store, collect, or access your personal data
❌ Have control over third-party service data practices
❌ Guarantee third-party service availability or performance
❌ Take responsibility for third-party privacy policies
❌ Store conversations, tasks, or personal information

═══════════════════════════════════════════

3. THIRD-PARTY SERVICES LIABILITY DISCLAIMER

OPENAI SERVICES:
• OpenAI provides AI text processing services
• OpenAI has separate terms of service and privacy policies
• Users consent directly to OpenAI when using AI features
• Motivator AI is NOT LIABLE for OpenAI's data practices
• Motivator AI is NOT RESPONSIBLE for OpenAI service issues
• Users assume all risk when using OpenAI-powered features

ELEVENLABS SERVICES:
• ElevenLabs provides voice generation services
• ElevenLabs has separate terms of service and privacy policies
• Users consent directly to ElevenLabs when using voice features
• Motivator AI is NOT LIABLE for ElevenLabs' data practices
• Motivator AI is NOT RESPONSIBLE for ElevenLabs service issues
• Users assume all risk when using ElevenLabs-powered features

═══════════════════════════════════════════

4. USER RESPONSIBILITIES

YOU ARE RESPONSIBLE FOR:
• Reviewing third-party service terms before use
• Understanding data sharing implications
• Enabling/disabling features based on your comfort level
• Using offline mode if you want complete privacy
• Keeping your device secure
• Regular data backups if desired

═══════════════════════════════════════════

5. DATA AND PRIVACY

MOTIVATOR AI COMMITMENT:
• All user data stays on your device
• We cannot access your personal information
• No data uploaded to our servers without explicit consent
• Full transparency about data flow
• Complete user control over all features

THIRD-PARTY DATA FLOW:
• AI features may send text to OpenAI
• Voice features may send text to ElevenLabs
• You control which features to enable
• You can disable all external data sharing
• Third-party services have independent privacy policies

═══════════════════════════════════════════

6. LIMITATION OF LIABILITY

TO THE MAXIMUM EXTENT PERMITTED BY LAW:

MOTIVATOR AI IS NOT LIABLE FOR:
• Third-party service data breaches or privacy violations
• OpenAI or ElevenLabs service interruptions
• Loss of data due to third-party service issues
• Decisions made based on AI-generated content
• External service terms changes or policy updates
• Any damages arising from third-party service use

YOUR SOLE REMEDY:
• Disable problematic features
• Contact third-party services directly for their issues
• Use app in offline mode
• Stop using the app

═══════════════════════════════════════════

7. DISCLAIMER OF WARRANTIES

THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND.

WE DISCLAIM ALL WARRANTIES INCLUDING:
• Fitness for a particular purpose
• Merchantability
• Non-infringement
• Uninterrupted service
• Error-free operation
• Third-party service reliability

═══════════════════════════════════════════

8. INDEMNIFICATION

You agree to indemnify and hold Motivator AI harmless from:
• Claims arising from your use of third-party services
• Violations of third-party terms of service
• Data breaches by external services
• Your use of AI-generated content
• Any content you input into the app

═══════════════════════════════════════════

9. MODIFICATIONS

We may modify these terms at any time.
Continued use constitutes acceptance of new terms.
Material changes will be prominently displayed in the app.

═══════════════════════════════════════════

10. GOVERNING LAW

These terms are governed by [YOUR JURISDICTION] law.
Disputes will be resolved in [YOUR JURISDICTION] courts.

═══════════════════════════════════════════

11. CONTACT INFORMATION

For app-related issues: [Your Support Email]
For OpenAI issues: contact@openai.com
For ElevenLabs issues: support@elevenlabs.io

═══════════════════════════════════════════

12. ENTIRE AGREEMENT

These terms, along with our Privacy Policy, constitute the entire 
agreement between you and Motivator AI.

═══════════════════════════════════════════

BY USING THIS APP, YOU ACKNOWLEDGE:
✅ You understand the third-party service disclaimers
✅ You take responsibility for reviewing external privacy policies
✅ You accept that Motivator AI is not liable for third-party practices
✅ You have control to disable all external data sharing
✅ You can use the app in completely offline mode
''';
  }

  /// Generate privacy policy with liability protection
  static String getPrivacyPolicy() {
    return '''
MOTIVATOR AI - PRIVACY POLICY

Last Updated: ${DateTime.now().toString().split(' ')[0]}

═══════════════════════════════════════════

PRIVACY-FIRST PHILOSOPHY

Motivator AI is designed with privacy as the foundation. We believe 
your personal data belongs to YOU, not us.

═══════════════════════════════════════════

1. WHAT MOTIVATOR AI COLLECTS

PERSONAL DATA: NONE
• We do NOT collect personal information
• We do NOT store conversations or tasks
• We do NOT access your device data without permission
• We do NOT upload data to our servers

TECHNICAL DATA: MINIMAL
• App crash reports (anonymous, no personal data)
• Anonymous usage statistics (if opted in)
• Device compatibility information (anonymous)

═══════════════════════════════════════════

2. THIRD-PARTY SERVICE DATA SHARING

When you CHOOSE to enable certain features, data may be shared with:

OPENAI (AI Processing):
• What's shared: Text you input for AI processing
• When: Only when you use AI reflection features
• Purpose: Generate AI responses and conversations
• Control: Disable AI features to stop sharing
• Liability: OpenAI's privacy policy applies, not ours

ELEVENLABS (Voice Generation):
• What's shared: Text for voice conversion
• When: Only when you use voice generation features
• Purpose: Convert text to speech audio
• Control: Disable voice features to stop sharing
• Liability: ElevenLabs' privacy policy applies, not ours

═══════════════════════════════════════════

3. YOUR DATA CONTROL

COMPLETE CONTROL:
✅ Enable/disable any feature
✅ Use app completely offline
✅ Kill switch to delete all data
✅ Export all stored data
✅ Factory reset option

LOCAL STORAGE ONLY:
• All settings stored on your device
• No cloud synchronization without consent
• No remote access to your data
• No data transmission without explicit action

═══════════════════════════════════════════

4. THIRD-PARTY PRIVACY POLICIES

IMPORTANT: Review these independently

OpenAI Privacy Policy:
https://openai.com/privacy

ElevenLabs Privacy Policy:
https://elevenlabs.io/privacy

DISCLAIMER: We are NOT responsible for third-party data practices.

═══════════════════════════════════════════

5. DATA RETENTION

MOTIVATOR AI:
• We retain NO personal data (we don't collect any)
• Local app data stays on your device until you delete it
• Anonymous analytics retained for app improvement only
• No personal identifiers in any retained data

THIRD-PARTY SERVICES:
• OpenAI: Subject to their data retention policies
• ElevenLabs: Subject to their data retention policies
• Review their policies for specific retention periods
• Contact them directly for data deletion requests

═══════════════════════════════════════════

6. CHILDREN'S PRIVACY

• We do not knowingly collect data from children under 13
• No age verification required (no data collection)
• Parents should review third-party policies for children's use
• Parental supervision recommended for AI feature use

═══════════════════════════════════════════

7. DATA SECURITY

MOTIVATOR AI SECURITY:
✅ All data stored locally on your device
✅ No transmission without explicit consent
✅ Industry-standard app security practices
✅ No central database to be breached

YOUR RESPONSIBILITY:
• Keep your device secure (passcode, biometrics)
• Review app permissions regularly
• Update the app for security patches
• Use strong device security practices

═══════════════════════════════════════════

8. INTERNATIONAL DATA TRANSFERS

MOTIVATOR AI:
• No international transfers (no data collection)
• All processing happens on your local device

THIRD-PARTY SERVICES:
• OpenAI: May process data internationally
• ElevenLabs: May process data internationally
• Review their policies for transfer details
• Consider implications before enabling features

═══════════════════════════════════════════

9. YOUR RIGHTS

UNDER GDPR/CCPA (if applicable):
✅ Right to access: View all data via transparency report
✅ Right to deletion: Use kill switch or factory reset
✅ Right to portability: Export your data anytime
✅ Right to rectification: Edit/delete any stored data
✅ Right to object: Disable any data processing feature

FOR THIRD-PARTY DATA:
• Contact OpenAI/ElevenLabs directly for their data
• We cannot control or access third-party stored data
• Exercise rights directly with those services

═══════════════════════════════════════════

10. LIABILITY LIMITATIONS

MOTIVATOR AI IS NOT LIABLE FOR:
❌ Third-party data breaches or misuse
❌ OpenAI or ElevenLabs privacy violations
❌ External service data retention practices
❌ International data transfer by third parties
❌ Changes to third-party privacy policies
❌ Data loss due to external service issues

═══════════════════════════════════════════

11. PRIVACY POLICY CHANGES

• We will notify users of material changes
• Continued use constitutes acceptance
• Previous versions available upon request
• Changes won't affect previously collected data (we don't collect any)

═══════════════════════════════════════════

12. CONTACT FOR PRIVACY QUESTIONS

Motivator AI Privacy Questions:
[Your Privacy Contact Email]

Third-Party Privacy Questions:
• OpenAI: privacy@openai.com
• ElevenLabs: privacy@elevenlabs.io

═══════════════════════════════════════════

13. COMPLIANCE CERTIFICATIONS

• Privacy by Design principles
• GDPR compliance (no data collection = automatic compliance)
• CCPA compliance (no personal information sales)
• COPPA compliance (no children's data collection)

═══════════════════════════════════════════

SUMMARY: YOUR PRIVACY IS PROTECTED

✅ Motivator AI collects NO personal data
✅ All data stays on YOUR device
✅ YOU control all external data sharing
✅ Third-party services have separate policies
✅ Complete transparency and control provided

For maximum privacy: Use app in offline mode with all 
external features disabled.
''';
  }

  /// Generate data processing agreement for business users
  static String getDataProcessingAgreement() {
    return '''
MOTIVATOR AI - DATA PROCESSING AGREEMENT (DPA)

Effective Date: ${DateTime.now().toString().split(' ')[0]}

═══════════════════════════════════════════

This Data Processing Agreement ("DPA") supplements our Terms of Service 
and Privacy Policy for business or organizational users.

═══════════════════════════════════════════

1. DEFINITIONS

• "Personal Data" - Any information relating to an identified or 
  identifiable natural person
• "Processing" - Any operation performed on personal data
• "Controller" - The entity that determines purposes and means of processing
• "Processor" - The entity that processes data on behalf of the controller

═══════════════════════════════════════════

2. DATA CONTROLLER RELATIONSHIP

MOTIVATOR AI ROLE:
• Motivator AI is NOT a data processor
• Motivator AI does NOT process personal data on your behalf
• Motivator AI provides software tools only
• YOU remain the sole controller of your data

YOUR ROLE AS CONTROLLER:
• You control all data input into the app
• You decide which features to enable
• You manage consent for third-party services
• You are responsible for lawful processing

═══════════════════════════════════════════

3. THIRD-PARTY PROCESSOR RELATIONSHIPS

When you enable certain features:

OPENAI RELATIONSHIP:
• OpenAI becomes YOUR processor (not ours)
• You establish direct relationship with OpenAI
• OpenAI's DPA applies to your data processing
• Motivator AI is NOT party to this processing

ELEVENLABS RELATIONSHIP:
• ElevenLabs becomes YOUR processor (not ours)
• You establish direct relationship with ElevenLabs
• ElevenLabs' terms apply to your data processing
• Motivator AI is NOT party to this processing

═══════════════════════════════════════════

4. DATA MINIMIZATION

MOTIVATOR AI COMMITMENT:
✅ Process only data necessary for app functionality
✅ No collection of personal data
✅ Local processing where possible
✅ Transparent about all data flows

YOUR RESPONSIBILITY:
• Input only necessary data
• Review third-party data requirements
• Implement appropriate consent mechanisms
• Maintain records of processing activities

═══════════════════════════════════════════

5. SECURITY MEASURES

MOTIVATOR AI PROVIDES:
• Secure app architecture
• Local data storage by default
• Encryption in transit for external communications
• Regular security updates

YOU MUST PROVIDE:
• Device-level security measures
• Appropriate user access controls
• Staff training on data protection
• Incident response procedures

═══════════════════════════════════════════

6. DATA SUBJECT RIGHTS

For data processed by MOTIVATOR AI (minimal):
• We will assist with data subject requests
• Local data can be exported/deleted via app controls
• Response time: 30 days maximum

For data processed by THIRD-PARTY SERVICES:
• You must handle requests directly with those services
• Motivator AI cannot access or control third-party data
• Maintain direct relationships for compliance

═══════════════════════════════════════════

7. DATA BREACH NOTIFICATION

MOTIVATOR AI BREACHES:
• We will notify you within 72 hours of discovery
• Assistance with impact assessment provided
• Cooperation with regulatory notifications

THIRD-PARTY SERVICE BREACHES:
• You are responsible for monitoring third-party notices
• Motivator AI cannot detect external service breaches
• Maintain direct communication with all processors

═══════════════════════════════════════════

8. INTERNATIONAL TRANSFERS

MOTIVATOR AI:
• No international transfers (no data collection)
• All processing occurs on user devices locally

THIRD-PARTY SERVICES:
• May involve international transfers
• Your responsibility to ensure adequate safeguards
• Review their transfer mechanisms independently

═══════════════════════════════════════════

9. AUDIT RIGHTS

MOTIVATOR AI:
• Annual security assessments available upon request
• Documentation of security measures provided
• Reasonable cooperation with compliance audits

THIRD-PARTY SERVICES:
• Audit rights must be negotiated directly
• Review their audit and compliance documentation
• Maintain independent oversight

═══════════════════════════════════════════

10. TERMINATION

Upon termination of services:
• Local data remains on your devices
• No data stored by Motivator AI to delete
• Third-party relationships continue independently
• Your responsibility to manage third-party data deletion

═══════════════════════════════════════════

11. LIABILITY AND INDEMNIFICATION

MOTIVATOR AI LIABILITY:
• Limited to direct damages caused by our software
• No liability for third-party data processing
• Maximum liability: amount paid for app services

INDEMNIFICATION:
• You indemnify us against third-party processing claims
• We indemnify you against our software security failures
• Mutual cooperation on regulatory investigations

═══════════════════════════════════════════

12. GOVERNING LAW AND JURISDICTION

• Governed by [Your Jurisdiction] law
• EU Standard Contractual Clauses incorporated if applicable
• Disputes resolved in [Your Jurisdiction] courts

═══════════════════════════════════════════

This DPA forms part of our overall service agreement and 
clarifies data protection responsibilities in business contexts.

Contact: [Your Legal/Privacy Contact]
''';
  }

  /// Generate consent form templates
  static Map<String, String> getConsentTemplates() {
    return {
      'openai_consent': '''
CONSENT TO OPENAI DATA PROCESSING

By enabling AI features in Motivator AI, you consent to:

• Sending your text input to OpenAI for processing
• OpenAI generating AI responses based on your input
• OpenAI's terms of service and privacy policy applying
• Understanding that Motivator AI cannot control OpenAI's data practices

You can withdraw this consent by disabling AI features in settings.

Date: ${DateTime.now().toString().split(' ')[0]}
''',
      
      'elevenlabs_consent': '''
CONSENT TO ELEVENLABS DATA PROCESSING

By enabling voice features in Motivator AI, you consent to:

• Sending your text to ElevenLabs for voice generation
• ElevenLabs converting your text to speech audio
• ElevenLabs' terms of service and privacy policy applying
• Understanding that Motivator AI cannot control ElevenLabs' data practices

You can withdraw this consent by disabling voice features in settings.

Date: ${DateTime.now().toString().split(' ')[0]}
''',
      
      'analytics_consent': '''
CONSENT TO ANONYMOUS ANALYTICS

By enabling analytics, you consent to:

• Sharing anonymous usage statistics with Motivator AI
• No personal information or identifiable data included
• Data used only for app improvement purposes
• Ability to opt-out anytime in settings

Date: ${DateTime.now().toString().split(' ')[0]}
''',
    };
  }

  /// Check if user needs to see updated terms
  static Future<bool> needsTermsUpdate() async {
    // Implementation would check version numbers, last acceptance dates, etc.
    return false; // Placeholder
  }

  /// Record user acceptance of terms
  static Future<void> recordTermsAcceptance(String termsType) async {
    // Implementation would store acceptance date and version
    print('Terms accepted: $termsType on ${DateTime.now()}');
  }
}