// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_brevo/otel_brevo.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_brevo-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('smtp.template records product + template + recipients', () async {
    await tracedBrevo<String>(
      operation: 'smtp.template',
      product: 'transactional',
      invoke: () async => const BrevoCallResult(
        value: 'ok',
        result: BrevoResult(
          product: 'transactional',
          messageId: 'msg-1',
          recipientCount: 1,
          templateId: 42,
          tier: 'business',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('brevo smtp.template')!);
    expect(a['brevo.product'], 'transactional');
    expect(a['brevo.template.id'], 42);
    expect(a['brevo.tier'], 'business');
  });

  test('transactional_sms.send records type', () async {
    await tracedBrevo<String>(
      operation: 'transactional_sms.send',
      invoke: () async => const BrevoCallResult(
        value: 'ok',
        result: BrevoResult(product: 'sms', smsType: 'unicode'),
      ),
    );
    final a = attrsOf(spans.findSpanByName('brevo transactional_sms.send')!);
    expect(a['brevo.sms.type'], 'unicode');
  });

  test('suppression skips spans', () async {
    await runWithoutBrevoInstrumentationAsync(() async {
      await tracedBrevo<String>(
        operation: 'contacts.create',
        invoke: () async => const BrevoCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('brevo '), isEmpty);
  });
}
