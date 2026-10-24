// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_brevo_suppression.dart';

const _tracerName = 'dartastic_otel_libs_brevo';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class BrevoResult {
  /// Creates a result.
  const BrevoResult({
    this.product,
    this.messageId,
    this.recipientCount,
    this.templateId,
    this.smsType,
    this.campaignType,
    this.tier,
    this.requestId,
    this.statusCode,
  });

  /// `transactional` / `marketing` / `sms` / `contacts` / `conversations`
  /// / `whatsapp` / `inbound` — Brevo's product lines are billed
  /// independently.
  final String? product;

  /// `messageId` returned for transactional sends.
  final String? messageId;

  /// Recipient count on the send.
  final int? recipientCount;

  /// Template id used.
  final int? templateId;

  /// `marketing` / `transactional` / `unicode` for SMS.
  final String? smsType;

  /// `classic` / `trigger` for marketing campaigns.
  final String? campaignType;

  /// `free` / `starter` / `business` / `enterprise`.
  final String? tier;

  /// `X-Mailin-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class BrevoCallResult<T> {
  /// Creates a call result.
  const BrevoCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final BrevoResult? result;
}

/// Wraps a Brevo API call in a CLIENT span. [operation] is one of
/// `smtp.send`, `smtp.template`, `smtp.email_events.get`,
/// `smtp.blocked_contacts.list`, `marketing.email_campaigns.send`,
/// `transactional_sms.send`, `marketing_sms.send`, `whatsapp.send`,
/// `contacts.create`, `contacts.update`, `contacts.import`,
/// `contacts.lists.list`, `conversations.message.send`,
/// `webhooks.create`, `account.get`.
Future<T> tracedBrevo<T>({
  required String operation,
  required Future<BrevoCallResult<T>> Function() invoke,
  String? product,
}) async {
  if (brevoInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'brevo',
    'rpc.method': operation,
    'brevo.operation': operation,
  };
  if (product != null) m['brevo.product'] = product;

  final span = _tracer().startSpan(
    'brevo $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.product != null) {
        extras.add(OTelAPI.attributeString(
          'brevo.product',
          r.result!.product!,
        ));
      }
      if (r.result!.messageId != null) {
        extras.add(OTelAPI.attributeString(
          'brevo.message.id',
          r.result!.messageId!,
        ));
      }
      if (r.result!.recipientCount != null) {
        extras.add(OTelAPI.attributeInt(
          'brevo.recipient_count',
          r.result!.recipientCount!,
        ));
      }
      if (r.result!.templateId != null) {
        extras.add(OTelAPI.attributeInt(
          'brevo.template.id',
          r.result!.templateId!,
        ));
      }
      if (r.result!.smsType != null) {
        extras.add(OTelAPI.attributeString(
          'brevo.sms.type',
          r.result!.smsType!,
        ));
      }
      if (r.result!.campaignType != null) {
        extras.add(OTelAPI.attributeString(
          'brevo.campaign.type',
          r.result!.campaignType!,
        ));
      }
      if (r.result!.tier != null) {
        extras.add(OTelAPI.attributeString(
          'brevo.tier',
          r.result!.tier!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'brevo.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Brevo HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
