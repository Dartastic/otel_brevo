// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_brevo/otel_brevo.dart';

/// Traces Brevo calls with OpenTelemetry.
///
/// `otel_brevo` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Brevo call in
/// [tracedBrevo]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'brevo-example');

  // Wraps a Brevo API call in a CLIENT span.
  final brevoId = await tracedBrevo<String>(
    operation: 'contacts.create',
    product: 'example',
    invoke: () async {
      // Make the Brevo call here, then report what it returned.
      const id = 'brevo_8f3a2c';
      return const BrevoCallResult(
          value: id,
          result: BrevoResult(
              product: 'transactional',
              messageId: 'message_8f3a2c',
              recipientCount: 3,
              templateId: 1,
              smsType: 'marketing',
              campaignType: 'classic',
              tier: 'free',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedBrevo contacts.create returned $brevoId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutBrevoInstrumentationAsync.
  await runWithoutBrevoInstrumentationAsync(
    () => tracedBrevo<String>(
      operation: 'contacts.create',
      product: 'example',
      invoke: () async {
        const id = 'brevo_8f3a2c';
        return const BrevoCallResult(
            value: id,
            result: BrevoResult(
                product: 'transactional',
                messageId: 'message_8f3a2c',
                recipientCount: 3,
                templateId: 1,
                smsType: 'marketing',
                campaignType: 'classic',
                tier: 'free',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
