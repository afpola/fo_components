// Copyright (c) 2017, Muienog AB. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' as dom;
import 'dart:math';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import '../fo_modal_component/fo_modal_component.dart';
import '../fo_select_component/fo_select_component.dart';
import '../../model/fo_model.dart';
import '../../pipes/phrase_pipe.dart';
import '../../pipes/range_pipe.dart';

@Component(
    selector: 'fo-data-table',
    styleUrls: const ['fo_data_table_component.scss.css'],
    templateUrl: 'fo_data_table_component.html',
    directives: const [CORE_DIRECTIVES, FoModalComponent, FoSelectComponent, materialDirectives, MaterialIconComponent],
    pipes: const [PhrasePipe, RangePipe],
    changeDetection: ChangeDetectionStrategy.Default,
    visibility: Visibility.none)

class DataTableComponent implements OnChanges, OnInit, OnDestroy
{
  DataTableComponent();

  void ngOnInit()
  {
    selectedRowOptionId = rowOptions.optionsList.firstWhere((r) => r.count == rows, orElse: () => rowOptions.optionsList.first).id;
    firstIndex = 0;
    lastIndex = _selectedRowOption.count;

    if (data == null) data = new Map();
  }

  void ngOnChanges(Map<String, SimpleChange> changes)
  {
    if (changes.containsKey("rows") || changes.containsKey("data"))
    {
      if (data == null) data = new Map();

      selectedRowOptionId = rowOptions.optionsList.firstWhere((r) => r.count == rows, orElse: () => rowOptions.optionsList.first).id;

      onSearch();
      setIndices(0);
    }
  }

  void ngOnDestroy()
  {
    onCellClickController.close();
    onDeleteController.close();
    onRowClickController.close();
    onSelectedRowsController.close();
    _onSortController.close();
  }

  void step(int steps)
  {
    setIndices(firstIndex + (steps * _selectedRowOption.count));
  }

  void onSearchKeyUp(dom.KeyboardEvent e)
  {
    if (data.length < 500) onSearch();
    else if (e.keyCode == dom.KeyCode.ENTER || e.keyCode == dom.KeyCode.MAC_ENTER) onSearch();
  }

  void onSearch()
  {
    sortColumn = null;

    if (searchPhrase != null && searchPhrase.isNotEmpty)
    {
      bool find(FoModel model, List<String> keywords)
      {
        bool allKeywords;
        for (String keyword in keywords)
        {
          allKeywords = false;
          for (String col in columns)
          {
            if (model[col].toString().toLowerCase().contains(keyword))
            {
              allKeywords = true;
              break;
            }
          }
          if (allKeywords == false) return false;
        }
        return true;
      }
      List<String> keywords = searchPhrase.toLowerCase().split(" ");
      print(keywords);
      _filteredKeys = data.keys.where((key) => find(data[key], keywords));
    }
    else _filteredKeys = null;

    setIndices(0);
  }

  void onSort(String column)
  {
    if (!disabled)
    {
      sortColumn = column;
      sortOrder = (sortOrder == "ASC") ? "DESC" : "ASC";

      if (sortOrder != null && sortColumn != null && sortColumn.isNotEmpty)
      {
        int sort(String a, String b)
        {
          if (a == null) a = "-";
          if (b == null) b = "-";

          try
          {
            // Number comparison
            num numA = num.parse(a);
            num numB = num.parse(b);
            return (sortOrder == "ASC") ? (numA - numB).toInt() : (numB - numA).toInt();
          }
          on FormatException
          {
            try
            {
              // Date comparison
              DateTime dateA = DateTime.parse(a);
              DateTime dateB = DateTime.parse(b);
              return (sortOrder == "ASC") ? (dateA.difference(dateB)).inMinutes : (dateB.difference(dateA)).inMinutes;
            }
            on FormatException
            {
              // Default String comparison
              String colA = a.toLowerCase();
              String colB = b.toLowerCase();

              return (sortOrder == "ASC") ? colA.compareTo(colB) : colB.compareTo(colA);
            }
          }
        }

        List<FoModel> values = data.keys.where(filteredKeys.contains).map((key) => data[key]).toList();
        if (values != null)
        {
          values.sort((FoModel a, FoModel b) => sort(a[sortColumn].toString(), b[sortColumn].toString()));
          _filteredKeys = values.map((model) => model["id"]);
        }
      }
    }
  }

  void onDownloadDataCSV()
  {
    if (data.isNotEmpty)
    {
      /**
       * Generate CSV string (Property1;Property2;Property3;Property4;Property5\n)
       */
      StringBuffer sb = new StringBuffer();

      sb.writeln(columns);

      for (String key in filteredKeys)
      {
        FoModel model = data[key];
        if (model == null) continue;

        List<String> properties = columns.map((col) => model[col].toString()).toList(growable: false);

        /// Add "'"-character if ¨the cell has a leading '0'-character. This will stop Excel from skipping leading 0
        for (String property in properties)
        {
          try
          {
            num.parse(property);
            if (property.startsWith("0")) property = '="' + property + '"';
          }
          catch (e) { /* Not a number, continue */ }
        }
        sb.writeln(properties.join(";"));
      }

      String csv = Uri.encodeComponent(sb.toString());
      /* \uFEFF: UTF-8 BOM */
      new dom.AnchorElement(href:"data:text/csv;charset=utf-8,\uFEFF$csv")
        ..setAttribute("download", "data.csv")
        ..click();
    }
  }

  void setIndices(int first_index)
  {
    if (first_index < 0 || first_index >= data.length) return;

    firstIndex = first_index;
    if (searchPhrase != null && searchPhrase.isNotEmpty) firstIndex = max(0, min(firstIndex, filteredKeys.length - _selectedRowOption.count));
    lastIndex = firstIndex + _selectedRowOption.count;

    currentPage = (data.isEmpty) ? 0 : (firstIndex.toDouble() / _selectedRowOption.count).ceil() + 1;
  }

  int get totalPages => (filteredKeys.length.toDouble() / _selectedRowOption.count).ceil();

  final StringSelectionOptions<RowOption> rowOptions = new StringSelectionOptions(
  [
    new RowOption("5", 5),
    new RowOption("10", 10),
    new RowOption("15", 15),
    new RowOption("20", 20),
    new RowOption("25", 25),
    new RowOption("50", 50),
    new RowOption("100", 100),
  ]);

  void onCheckedChange(String id, bool state)
  {
    if (state) selectedRows.add(id);
    else selectedRows.remove(id);
    onSelectedRowsController.add(selectedRows);
  }

  void onAllCheckedChange(bool state)
  {
    if (state == true) selectedRows = filteredKeys.toList();
    else selectedRows.clear();
  }

  Iterable<String> get filteredKeys => _filteredKeys == null ? data.keys : _filteredKeys;

  RowOption _selectedRowOption;

  String get selectedRowOptionId => _selectedRowOption?.id;
  void set selectedRowOptionId(String value)
  {
    _selectedRowOption = rowOptions.optionsList.firstWhere((row) => row.id == value, orElse: () => rowOptions.optionsList.first);
  }

  String deleteBufferId;
  int firstIndex = 0;
  int lastIndex = 1;
  int currentPage = 1;
  String sortColumn = "";
  String sortOrder = "DESC";
  String searchPhrase = "";
  Iterable<String> _filteredKeys;
  bool infoModalOpen = false;

  final StreamController<String> onCellClickController = new StreamController();
  final StreamController<List<String>> onSelectedRowsController = new StreamController();
  final StreamController<String> onDeleteController = new StreamController();
  final StreamController<String> onRowClickController = new StreamController();
  final StreamController<Map<String, String>> _onSortController = new StreamController();

  @Input('large-hidden-col')
  List<String> largeHiddenCol = [];

  @Input('small-hidden-col')
  List<String> smallHiddenCol = [];

  @Input('medium-hidden-col')
  List<String> mediumHiddenCol = [];

  @Input('data')
  Map<String, FoModel> data = new Map();

  @Input('columns')
  List<String> columns = new List();

  @Input('showCheckboxes')
  bool showCheckboxes = false;

  @Input('title')
  String title = "";

  @Input('description')
  String description;

  @Input('selectedRows')
  List<String> selectedRows = new List();

  @Input('rows')
  int rows = 10;

  @Input('disabled')
  bool disabled = false;

  @Input('showDeleteButtons')
  bool showDeleteButtons = false;

  @Input('showDownloadButton')
  bool showDownloadButton = true;

  @Output('cellclick')
  Stream<String> get onCellClickOutput => onCellClickController.stream;

  @Output('delete')
  Stream<String> get onDeleteOutput => onDeleteController.stream;

  @Output('rowclick')
  Stream<String> get onRowClickOutput => onRowClickController.stream;

  @Output('selectedRowsChange')
  Stream<List<String>> get selectedRowsChange => onSelectedRowsController.stream;

  @Output('sort')
  Stream<Map<String, String>> get onSortOutput => _onSortController.stream;
}

class RowOption implements FoModel
{
  RowOption(this.id, this.count);

  @override
  RowOption.fromMap(Map<dynamic, dynamic> map);

  @override
  dynamic operator[](Object key) => throw new UnsupportedError("Operator [] is not supported for RowOption");

  @override operator[]=(Object key, dynamic value) => throw new UnsupportedError("Operator []= is not supported for RowOption");

  @override
  String toString() => count.toString();

  @override
  Map<dynamic, dynamic> toMap() => throw new UnsupportedError("toMap() is not supported for RowOption");

  int count;
  @override String id;
}