// Copyright (c) 2016, BuyByMarcus Ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' as dom;
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import '../../pipes/phrase_pipe.dart';

@Component(
    selector: 'fo-file-upload',
    templateUrl: 'fo_file_upload_component.html',
    styleUrls: const <String> ['fo_file_upload_component.css'],
    directives: const <dynamic> [coreDirectives, materialDirectives],
    pipes: const <Type> [PhrasePipe],
    visibility: Visibility.local)
class FileUploadComponent implements OnDestroy
{
  FileUploadComponent();

  @override
  void ngOnDestroy()
  {
    onUploadController.close();
  }

  void onDrop(dom.MouseEvent event)
  {
    event.preventDefault();
    final dt = event.dataTransfer;
    file = (dt.files.isEmpty) ? null : file = dt.files.last;
  }

  void onFileChange(dom.Event event)
  {
    _fileInput = event.target;
    file = (_fileInput.files.isNotEmpty) ? _fileInput.files.last : null;
  }

  void clearSelection()
  {
    file = null;
    _fileInput?.value = '';
  }

  void upload()
  {
    onUploadController.add(file);
    clearSelection();
  }

  bool get valid => file != null && file.size <= maxByteSize;

  dom.FileUploadInputElement _fileInput;
  dom.File file;

  @Input()
  String accept = 'image/*,.pdf';

  @Input()
  bool disabled = false;

  @Input()
  String label = 'File';

  @Input()
  int maxByteSize = 1048576;

  @Output('upload')
  Stream<dom.File> get onUploadOutput => onUploadController.stream;

  StreamController<dom.File> onUploadController = new StreamController();
}