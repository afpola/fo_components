// Copyright (c) 2017, Patrick Minogue. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import '../../pipes/phrase_pipe.dart';

@Component(
    selector: 'fo-number-input',
    styleUrls: const ['fo_number_input_component.scss.css'],
    templateUrl: 'fo_number_input_component.html',
    directives: const [CORE_DIRECTIVES, materialDirectives],
    pipes: const [PhrasePipe],
    visibility: Visibility.none
)
class FoNumberInputComponent implements OnDestroy
{
  FoNumberInputComponent();

  void ngOnDestroy()
  {
    _onValueChangeController.close();
  }

  void onMouseDown(num count)
  {
    add(count);

    autoAddTimer?.cancel();
    addStepTimer?.cancel();
    addStepTimer = null;

    autoAddTimer = new Timer(const Duration(milliseconds: 600), ()
    {
      autoAddTimer = null;
      addStepTimer?.cancel();
      addStepTimer = new Timer.periodic(const Duration(milliseconds: 20), (_) => add(count));
    });
  }

  void onMouseUp()
  {
    autoAddTimer?.cancel();
    addStepTimer?.cancel();
    autoAddTimer = null;
    addStepTimer = null;
  }

  void add(num count)
  {
    if (value + count >= min && value + count <= max)
    {
      value += count;
      _onValueChangeController.add(value);
    }
  }

  final StreamController<num> _onValueChangeController = new StreamController();

  @Input('disabled')
  bool disabled = false;

  @Input('label')
  String label = "value";

  @Input('leadingText')
  String leadingText = "";

  @Input('max')
  num max = 9999;

  @Input('min')
  num min = 0;

  @Input('step')
  num step = 1;

  @Input('trailingText')
  String trailingText = "";

  @Input('value')
  num value = 0;

  @Output('valueChange')
  Stream<num> get onValueChangeOutput => _onValueChangeController.stream;

  Timer autoAddTimer;
  Timer addStepTimer;
}