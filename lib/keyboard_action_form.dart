import 'package:cooldown_button/cooldown_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
export 'package:flutter_form_builder/flutter_form_builder.dart';
export 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
export 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:async';

class FormBuilderTextFieldWrapper extends StatefulWidget {
  final FocusNode focusNode;
  final String name;
  final String? initialValue;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final ValueTransformer<String?>? valueTransformer;
  final TextInputType? keyboardType;
  final int? maxLines;
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
    this.maxLines,
  });

  @override
  State<FormBuilderTextFieldWrapper> createState() =>
      _FormBuilderTextFieldWrapperState();
}

class _FormBuilderTextFieldWrapperState
    extends State<FormBuilderTextFieldWrapper> {
  late TextEditingController textEditingController;
  late ValueNotifier<bool> _controllerTextNotEmptyNotifier;

  @override
  void initState() {
    textEditingController = TextEditingController();
    textEditingController.text = widget.initialValue ?? '';
    _controllerTextNotEmptyNotifier =
        ValueNotifier(textEditingController.text.isNotEmpty);
    textEditingController.addListener(() {
      _controllerTextNotEmptyNotifier.value =
          textEditingController.text.isNotEmpty;
    });
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    _controllerTextNotEmptyNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _controllerTextNotEmptyNotifier,
      builder: (context, isNotEmpty, child) {
        return FormBuilderTextField(
          autocorrect: false,
          focusNode: widget.focusNode,
          name: widget.name,
          controller: textEditingController,
          decoration: widget.decoration.copyWith(
            suffixIcon: isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textEditingController.clear();
                      widget.onChanged?.call(null);
                    },
                  )
                : null,
          ),
          validator: widget.validator,
          enabled: widget.enabled,
          valueTransformer: widget.valueTransformer,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
        );
      },
    );
  }
}

class TypeAheadController<T> {
  _FormBuilderTypeAheadWrapperState<T>? _state;

  void updateValue(T newValue, String formName, BuildContext context) {
    _state?.updateValue(newValue);

    final formBuilder = FormBuilder.of(context);
    if (formBuilder != null) {
      formBuilder.patchValue({formName: newValue});
      // Trigger form validation to clear any validation errors
      formBuilder.fields[formName]?.validate();
    } else {
      print('FormBuilderState not found in the context.');
    }
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
  final FutureOr<List<T>?> Function(String) suggestionsCallback;
  final Widget Function(BuildContext, T) itemBuilder;
  final ValueChanged<T?>? onChanged;
  final FocusNode focusNode;
  final GestureTapCallback? onTap;
  final BoxConstraints? constraints;

  const FormBuilderTypeAheadWrapper({
    super.key,
    this.enabled = true,
    this.validate = true,
    this.onChanged,
    this.onTap,
    this.constraints,
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
  late ValueNotifier<String> userInputNotifier;
  late TextEditingController textEditingController;

  listener() {
    if (textEditingController.text != userInputNotifier.value) {
      userInputNotifier.value = textEditingController.text;
    }
  }

  void updateValue(T newValue) {
    final newText = widget.selectionToTextTransformer(newValue);
    // Remove listener temporarily to avoid triggering during programmatic update
    textEditingController.removeListener(listener);
    userInputNotifier.value = newText;
    textEditingController.text = newText;
    // Re-add listener after update
    textEditingController.addListener(listener);
  }

  @override
  void initState() {
    textEditingController = TextEditingController()
      ..text = widget.selectionToTextTransformer(widget.initialValue);
    userInputNotifier = ValueNotifier<String>(textEditingController.text);

    textEditingController.addListener(listener);
    widget.controller?._state = this;
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.removeListener(listener);
    // causes error, apparently its being disposed by FormBuilderTypeAhead
    // textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = FormBuilder.of(context);
    return ValueListenableBuilder(
      valueListenable: userInputNotifier,
      builder: (context, String userInput, _) {
        return FormBuilderTypeAhead<T>(
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          initialValue: widget.initialValue,
          name: widget.name,
          selectionToTextTransformer: widget.selectionToTextTransformer,
          constraints: widget.constraints,
          decoration: widget.decoration.copyWith(
            suffixIcon: widget.decoration.suffixIcon ??
                (userInput.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          textEditingController.text = '';
                          userInputNotifier.value = '';
                          formState?.fields[widget.name]?.didChange(null);
                          widget.onChanged?.call(null);
                        },
                      )
                    : null),
          ),
          suggestionsCallback: widget.suggestionsCallback,
          itemBuilder: widget.itemBuilder,
          controller: textEditingController,
          onChanged: (value) {
            final newValueText = widget.selectionToTextTransformer(value as T);
            userInputNotifier.value = newValueText;
            widget.onChanged?.call(value);
          },
          emptyBuilder: (context) {
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
          customTextField: TextField(
            autocorrect: false,
            enableSuggestions: false,
            onTap: () {
              textEditingController.text = userInput;
              widget.onTap?.call();
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
      this.enableActionWhenNoChanges = true})
      : super(key: key);

  @override
  State<KeyboardActionForm> createState() => _KeyboardActionFormState();
}

class _KeyboardActionFormState extends State<KeyboardActionForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final List<FocusNode> focusNodes =
      List.generate(widget.length, (index) => FocusNode());
  late final ValueNotifier<bool> formChangedNotifier =
      ValueNotifier<bool>(widget.enableActionWhenNoChanges);

  @override
  void dispose() {
    for (var element in focusNodes) {
      element.dispose();
    }
    formChangedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // perhaps passing builder is in order? Anyway this line needs to be here, its essential to rebuild items when KeyboardActionForm gets rebuild
    final List items = widget.itemsCallback.call(focusNodes);
    return FormBuilder(
      onChanged: () {
        formChangedNotifier.value = true;
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
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Cancel'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.onDelete != null)
                            CooldownButton(
                              confirmText: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Text(
                                  '${'Delete'.tr()}?',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onConfirm: () {
                                widget.onDelete?.call();
                              },
                              text: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Text(
                                  'Delete'.tr(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ValueListenableBuilder<bool>(
                            valueListenable: formChangedNotifier,
                            builder: (context, formChanged, child) {
                              return FilledButton(
                                onPressed: formChanged
                                    ? () {
                                        if (_formKey.currentState!
                                            .saveAndValidate(
                                                autoScrollWhenFocusOnInvalid:
                                                    true)) {
                                          Map<String, dynamic> formData =
                                              _formKey.currentState!.value;
                                          Navigator.of(context).pop(
                                              widget.onSave.call(formData));
                                        }
                                      }
                                    : null, // disable button when there's no change in form
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  elevation: 2.0,
                                ),
                                child: Text(
                                  widget.actionLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
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
