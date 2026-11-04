import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_workflow_store.dart';
import 'package:oreamnos/domain/models/facebook_publish_workflow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<FacebookWorkflowStore> store() async =>
      FacebookWorkflowStore(await SharedPreferences.getInstance());

  test('built-ins are always available', () async {
    final s = await store();
    expect(
      s.allWorkflows.map((w) => w.id),
      containsAll(['builtin-feed', 'builtin-feed-story', 'builtin-story']),
    );
    expect(s.defaultForPage('p1').id, 'builtin-feed');
  });

  test('save, default per Page, and cap at 10 custom workflows', () async {
    final s = await store();
    for (var i = 0; i < 12; i++) {
      await s.save(
        FacebookPublishWorkflow(
          id: 'w$i',
          name: 'Workflow $i',
          storyEnabled: i.isEven,
        ),
      );
    }
    expect(
      s.customWorkflows,
      hasLength(FacebookWorkflowStore.maxCustomWorkflows),
    );
    await s.setDefaultForPage('p1', 'w11');
    expect(s.defaultForPage('p1').id, 'w11');
    expect(s.defaultForPage('p2').id, 'builtin-feed');
  });

  test('deleting a workflow clears matching defaults', () async {
    final s = await store();
    await s.save(const FacebookPublishWorkflow(id: 'w1', name: 'One'));
    await s.setDefaultForPage('p1', 'w1');
    await s.delete('w1');
    expect(s.byId('w1'), isNull);
    expect(s.defaultForPage('p1').id, 'builtin-feed');
  });

  test('corrupt JSON falls back to built-ins', () async {
    SharedPreferences.setMockInitialValues({'facebook_workflows': 'not-json'});
    final s = await store();
    expect(s.customWorkflows, isEmpty);
    expect(s.allWorkflows, hasLength(3));
  });
}
