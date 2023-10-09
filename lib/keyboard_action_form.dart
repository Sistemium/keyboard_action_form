import 'package:cooldown_button/cooldown_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
export 'package:flutter_form_builder/flutter_form_builder.dart';
export 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
export 'package:form_builder_validators/form_builder_validators.dart';

class FormBuilderTextFieldWrapper extends StatefulWidget {
  final FocusNode focusNode;
  final String name;
  final String? initialValue;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final ValueTransformer<String?>? valueTransformer;
  final TextInputType? keyboardType;
  final ValueChanged? onChanged;

  const FormBuilderTextFieldWrapper({
    super.key,
    required this.focusNode,
    required this.name,
    this.initialValue,
    required this.decoration,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.valueTransformer,
    this.keyboardType,
  });

  @override
  State<FormBuilderTextFieldWrapper> createState() =>
      _FormBuilderTextFieldWrapperState();
}

class _FormBuilderTextFieldWrapperState
    extends State<FormBuilderTextFieldWrapper> {
  final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      autocorrect: false,
      focusNode: widget.focusNode,
      name: widget.name,
      initialValue: widget.initialValue ?? '',
      decoration: widget.decoration.copyWith(
        suffixIcon: textEditingController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    textEditingController.clear();
                    widget.onChanged?.call(null);
                  });
                },
              )
            : null,
      ),
      validator: widget.validator,
      enabled: widget.enabled,
      valueTransformer: widget.valueTransformer,
      keyboardType: widget.keyboardType,
    );
  }
}

class TypeAheadController<T> {
  _FormBuilderTypeAheadWrapperState<T>? _state;

  void updateValue(T newValue) {
    _state?.updateValue(newValue);
  }
}

class FormBuilderTypeAheadWrapper<T> extends StatefulWidget {
  final TypeAheadController<T>? controller;
  final T initialValue;
  final String name;
  final bool enabled;
  final bool validate;
  final SelectionToTextTransformer<T> selectionToTextTransformer;
  final InputDecoration decoration;
  final SuggestionsCallback<T> suggestionsCallback;
  final ItemBuilder<T> itemBuilder;
  final ValueChanged<T?>? onChanged;
  final FocusNode focusNode;

  const FormBuilderTypeAheadWrapper({
    super.key,
    this.enabled = true,
    this.validate = true,
    this.onChanged,
    required this.initialValue,
    required this.name,
    required this.selectionToTextTransformer,
    required this.decoration,
    required this.suggestionsCallback,
    required this.itemBuilder,
    required this.focusNode,
    this.controller,
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

  void updateValue(T newValue) {
    setState(() {
      userInput = widget.selectionToTextTransformer(newValue);
      textEditingController.text = userInput;
    });
  }

  @override
  void initState() {
    textEditingController = TextEditingController()
      ..text = widget.selectionToTextTransformer(widget.initialValue);

    textEditingController.addListener(listener);
    widget.controller?._state = this;
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.removeListener(listener);
    //causes error, apparently its being disposed by FormBuilderTypeAhead
    // textEditingController.dispose();
    widget.controller?._state = null;
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
      decoration: widget.decoration.copyWith(
        suffixIcon: textEditingController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    textEditingController.clear();
                    widget.onChanged?.call(null);
                  });
                },
              )
            : null,
      ),
      suggestionsCallback: widget.suggestionsCallback,
      itemBuilder: widget.itemBuilder,
      controller: textEditingController,
      onChanged: (value) {
        setState(() {
          selected = widget.selectionToTextTransformer(value as T);
          widget.onChanged?.call(value);
        });
      },
      noItemsFoundBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'No Items Found!'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).disabledColor, fontSize: 18.0),
          ),
        );
      },
      textFieldConfiguration: TextFieldConfiguration(
        autocorrect: false,
        enableSuggestions: false,
        onTap: () {
          textEditingController.text = userInput;
        },
      ),
      validator: (T? value) {
        if (widget.validate &&
            (value == null || textEditingController.text == '')) {
          return 'Field is required'.tr();
        }
        if (value != null &&
            textEditingController.text != '' &&
            widget.selectionToTextTransformer(value) !=
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
  final dynamic Function(Map<String, dynamic> data) onSave;
  final Function()? onDelete;
  final String actionLabel;
  final bool enableActionWhenNoChanges;
  const KeyboardActionForm(
      {Key? key,
      required this.itemsCallback,
      required this.onSave,
      this.onDelete,
      required this.length,
      required this.actionLabel,
      this.enableActionWhenNoChanges = false})
      : super(key: key);

  @override
  State<KeyboardActionForm> createState() => _KeyboardActionFormState();
}

class _KeyboardActionFormState extends State<KeyboardActionForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final List<FocusNode> focusNodes =
      List.generate(widget.length, (index) => FocusNode());
  late var formChanged = widget.enableActionWhenNoChanges;

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
                child: Column(
                  children: <Widget>[
                    ...items,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Cancel'.tr()),
                            ),
                          ),
                          if (widget.onDelete != null)
                            CooldownButton(
                              confirmText: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${'Delete'.tr()}?'),
                              ),
                              onConfirm: () {
                                widget.onDelete?.call();
                                Navigator.of(context).pop('delete');
                              },
                              text: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Delete'.tr()),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: formChanged
                                ? () {
                                    if (_formKey.currentState!.saveAndValidate(
                                        autoScrollWhenFocusOnInvalid: true)) {
                                      Map<String, dynamic> formData =
                                          _formKey.currentState!.value;
                                      Navigator.of(context)
                                          .pop(widget.onSave.call(formData));
                                    }
                                  }
                                : null, // disable button when there's no change in form
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(widget.actionLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
          );
        },
      ),
    );
  }
}
