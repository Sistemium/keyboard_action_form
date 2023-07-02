import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
export 'package:flutter_form_builder/flutter_form_builder.dart';

class FormBuilderTypeAheadWrapper<T> extends StatefulWidget {
  final T initialValue;
  final String name;
  final bool enabled;
  final SelectionToTextTransformer<T> selectionToTextTransformer;
  final InputDecoration decoration;
  final SuggestionsCallback<T> suggestionsCallback;
  final ItemBuilder<T> itemBuilder;
  final ValueChanged<T?>? onChanged;
  final FocusNode focusNode;

  const FormBuilderTypeAheadWrapper({
    super.key,
    this.enabled = true,
    this.onChanged,
    required this.initialValue,
    required this.name,
    required this.selectionToTextTransformer,
    required this.decoration,
    required this.suggestionsCallback,
    required this.itemBuilder,
    required this.focusNode,
  });

  @override
  State<FormBuilderTypeAheadWrapper<T>> createState() =>
      _FormBuilderTypeAheadWrapperState<T>();
}

class _FormBuilderTypeAheadWrapperState<T>
    extends State<FormBuilderTypeAheadWrapper<T>> {
  late String userInput =
      widget.selectionToTextTransformer(widget.initialValue);

  late String selected = widget.selectionToTextTransformer(widget.initialValue);

  late TextEditingController textEditingController;
  listener() {
    if (textEditingController.text != selected) {
      setState(() {
        userInput = textEditingController.text;
      });
    }
  }

  @override
  void initState() {
    textEditingController = TextEditingController()
      ..text = widget.selectionToTextTransformer(widget.initialValue);

    textEditingController.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.removeListener(listener);
    //causes error, apparently its being disposed by FormBuilderTypeAhead
    // textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderTypeAhead<T>(
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      initialValue: widget.initialValue,
      name: widget.name,
      selectionToTextTransformer: widget.selectionToTextTransformer,
      decoration: widget.decoration,
      suggestionsCallback: widget.suggestionsCallback,
      itemBuilder: widget.itemBuilder,
      controller: textEditingController,
      onChanged: (value) {
        setState(() {
          selected = widget.selectionToTextTransformer(value as T);
          widget.onChanged?.call(value);
        });
      },
      textFieldConfiguration: TextFieldConfiguration(
        autocorrect: false,
        enableSuggestions: false,
        onTap: () {
          textEditingController.text = userInput;
          widget.onChanged?.call(null);
        },
      ),
      validator: (T? value) {
        if (value == null || textEditingController.text == '') {
          return 'Field is required'.tr();
        }
        if (widget.selectionToTextTransformer(value) !=
            textEditingController.text) {
          return 'Unknown ${widget.name}';
        }
        return null;
      },
    );
  }
}

class KeyboardActionForm extends StatefulWidget {
  final List<Widget> Function(List<FocusNode> nodes) itemsCallback;
  final int length;
  final Function(Map<String, dynamic> data) onSave;
  final String actionLabel;
  const KeyboardActionForm(
      {Key? key,
      required this.itemsCallback,
      required this.onSave,
      required this.length,
      required this.actionLabel,
      })
      : super(key: key);

  @override
  State<KeyboardActionForm> createState() => _KeyboardActionFormState();
}

class _KeyboardActionFormState extends State<KeyboardActionForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final List<FocusNode> focusNodes =
      List.generate(widget.length, (index) => FocusNode());
  var formChanged = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var element in focusNodes) {
      element.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // perhaps passing builder is in order? Anyway this line needs to be here, its essentiol to rebuild items when KeyboardActionForm gets rebuild
    final List items = widget.itemsCallback.call(focusNodes);
    return FormBuilder(
      onChanged: () {
        setState(() {
          formChanged = true;
        });
      },
      key: _formKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return KeyboardActions(
            overscroll: 100,
            config: KeyboardActionsConfig(
              keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
              keyboardBarColor: Colors.grey[200],
              nextFocus: true,
              actions: focusNodes
                  .map((e) => KeyboardActionsItem(
                        focusNode: e,
                      ))
                  .toList(),
            ),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        45), //45 is size of keyboard bar, see keyboard_actions.dart:15
                child: IntrinsicHeight(
                  child: Column(
                    children: <Widget>[
                      ...items,
                      const Spacer(),
                      ButtonBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'.tr()),
                          ),
                          ElevatedButton(
                            onPressed: formChanged
                                ? () {
                                    if (_formKey.currentState!.saveAndValidate(
                                        autoScrollWhenFocusOnInvalid: true)) {
                                      Map<String, dynamic> formData =
                                          _formKey.currentState!.value;
                                      widget.onSave.call(formData);
                                      Navigator.of(context).pop();
                                    }
                                  }
                                : null, // disable button when there's no change in form
                            child: Text(widget.actionLabel),
                          ),
                        ],
                      )
                    ],
                  ),
                )),
          );
        },
      ),
    );
  }
}
