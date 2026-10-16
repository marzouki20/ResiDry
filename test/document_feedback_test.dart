import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/widgets/document_feedback.dart';

void main() {
  testWidgets('expiry, unreadable date and overload give actionable details',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final expired = documentIssues({
      'status': 'BLOCKED',
      'checks': [
        {
          'code': 'insurance_validity',
          'status': 'BLOCK',
          'details': {'reason': 'document_expired', 'expires_on': '2026-05-16'}
        }
      ]
    }).single;
    expect(expired.slots, ['INSURANCE']);
    expect(documentIssueMessage(context, expired), contains('16/05/2026'));
    expect(
        documentIssueMessage(
            context, const DocumentIssue('date_unreadable', ['INSURANCE'])),
        isNot(contains('Expired')));
    expect(
        documentIssueMessage(
            context,
            const DocumentIssue('wrong_document_type', ['AUTHORIZATION'],
                {'detected_kind': 'TECHNICAL_INSPECTION'})),
        contains('technical-inspection'));
    expect(
        documentIssueMessage(
            context,
            const DocumentIssue('load_within_payload', ['BACK'],
                {'payload_kg': 410, 'declared_kg': 200, 'reserve_kg': 250})),
        contains('450 kg'));
  });
  test('wrong document points to its exact field', () {
    final issues = documentIssues({
      'status': 'BLOCKED',
      'documents': [
        {
          'slot': 'LICENSE_BACK',
          'status': 'BLOCK',
          'reasons': ['wrong_document_type']
        }
      ]
    });
    expect(issues.single.slots, ['LICENSE_BACK']);
    expect(issues.single.code, 'wrong_document_type');
  });
  test('cross-document mismatch identifies both documents', () {
    final issues = documentIssues({
      'status': 'BLOCKED',
      'checks': [
        {'code': 'insurance_vehicle_matches', 'status': 'BLOCK'},
        {'code': 'insurance_validity', 'status': 'PASS'}
      ]
    });
    expect(issues.single.slots, ['INSURANCE', 'FRONT']);
  });
  test('outage does not blame any photo', () {
    expect(documentIssues({'status': 'UNAVAILABLE'}), isEmpty);
  });
  testWidgets('unreadable and wrong type give different corrections',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    expect(documentCorrection(context, 'unreadable_photo'), contains('blur'));
    expect(documentCorrection(context, 'wrong_document_type'),
        contains('requested document'));
    expect(documentCorrection(context, 'load_within_payload'),
        contains('does not fix overload'));
  });
}
