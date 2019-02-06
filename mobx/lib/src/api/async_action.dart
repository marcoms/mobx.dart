import 'dart:async';

import 'package:mobx/mobx.dart';

class AsyncAction {
  AsyncAction(String name, {ReactiveContext context})
      : this._(context ?? mainContext, name);

  AsyncAction._(ReactiveContext context, String name)
      : assert(context != null),
        assert(name != null),
        _actions = ActionController(context: context, name: name);

  final ActionController _actions;

  Zone _zoneField;
  Zone get _zone {
    if (_zoneField == null) {
      final spec = ZoneSpecification(
          run: _run, runUnary: _runUnary, runBinary: _runBinary);
      _zoneField = Zone.current.fork(specification: spec);
    }
    return _zoneField;
  }

  Future<R> run<R>(Future<R> Function() body) async {
    try {
      return await _zone.run(body);
    } finally {
      // @katis:
      // Delay completion until next microtask completion.
      // Needed to make sure that all mobx state changes are
      // applied after `await run()` completes, not sure why.
      await Future.microtask(_noOp);
    }
  }

  static dynamic _noOp() => null;

  R _run<R>(Zone self, ZoneDelegate parent, Zone zone, R Function() f) {
    final prevDerivation = _actions.startAction();
    try {
      final result = parent.run(zone, f);
      return result;
    } finally {
      _actions.endAction(prevDerivation);
    }
  }

  R _runUnary<R, A>(
      Zone self, ZoneDelegate parent, Zone zone, R Function(A a) f, A a) {
    final prevDerivation = _actions.startAction();
    try {
      final result = parent.runUnary(zone, f, a);
      return result;
    } finally {
      _actions.endAction(prevDerivation);
    }
  }

  R _runBinary<R, A, B>(Zone self, ZoneDelegate parent, Zone zone,
      R Function(A a, B b) f, A a, B b) {
    final prevDerivation = _actions.startAction();
    try {
      final result = parent.runBinary(zone, f, a, b);
      return result;
    } finally {
      _actions.endAction(prevDerivation);
    }
  }
}