import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class FormBuilderTextFieldWrapper extends StatelessWidget {
  final focusNode = FocusNode();
  final String name;
  final String initialValue;
  final InputDecoration decoration;

  FormBuilderTextFieldWrapper({
    super.key,
    required this.name,
    required this.initialValue,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      autocorrect: false,
      focusNode: focusNode,
      name: name,
      initialValue: initialValue,
      decoration: decoration,
    );
  }
}

class FormBuilderTypeAheadWrapper<T> extends ConsumerWidget {
  final focusNode = FocusNode();
  final T initialValue;
  final String name;
  final bool enabled;
  final SelectionToTextTransformer<T> selectionToTextTransformer;
  final InputDecoration decoration;
  final SuggestionsCallback<T> suggestionsCallback;
  final ItemBuilder<T> itemBuilder;
  late final userInput = StateProvider.autoDispose((ref) {
    return selectionToTextTransformer(initialValue);
  });

  late final selectedProvider = StateProvider.autoDispose(
      (ref) => selectionToTextTransformer(initialValue));

  late final textEditingControllerProvider =
      Provider.autoDispose<TextEditingController>((ref) {
    final controller = TextEditingController()
      ..text = selectionToTextTransformer(initialValue);
    controller.addListener(() {
      if (controller.text != ref.read(selectedProvider)) {
        ref.read(userInput.notifier).state = controller.text;
      }
    });
    ref.onDispose(() {
      controller.dispose();
    });
    return controller;
  });

  FormBuilderTypeAheadWrapper(
      {super.key,
      required this.enabled, 
      required this.initialValue,
      required this.name,
      required this.selectionToTextTransformer,
      required this.decoration,
      required this.suggestionsCallback,
      required this.itemBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userInput);
    ref.watch(selectedProvider);
    return FormBuilderTypeAhead<T>(
      enabled: enabled,
      focusNode: focusNode,
      initialValue: initialValue,
      name: this.name,
      selectionToTextTransformer: this.selectionToTextTransformer,
      decoration: this.decoration,
      suggestionsCallback: suggestionsCallback,
      itemBuilder: itemBuilder,
      controller: ref.watch(textEditingControllerProvider),
      onChanged: (value) {
        ref.read(selectedProvider.notifier).state =
            this.selectionToTextTransformer(value as T);
      },
      textFieldConfiguration: TextFieldConfiguration(
        autocorrect: false,
        onTap: () {
          ref.read(textEditingControllerProvider).text = ref.read(userInput);
        },
      ),
      validator: (T? value) {
        if (value == null ||
            ref.read(textEditingControllerProvider).text == '') {
          return 'Field is required'.tr();
        }
        if (selectionToTextTransformer(value) !=
            ref.read(textEditingControllerProvider).text) {
          return 'Unknown $name';
        }
        return null;
      },
    );
  }
}

class KeyboardActionForm extends ConsumerWidget {
  final List items;
  final Function(Map<String, dynamic> data) onSave;
  final _formKey = GlobalKey<FormBuilderState>();
  final formChangedProvider = StateProvider.autoDispose<bool>((ref) => false);

  KeyboardActionsConfig _buildConfig(BuildContext context, WidgetRef ref) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.grey[200],
      nextFocus: true,
      actions: items
          .map((e) => KeyboardActionsItem(
                focusNode: e.focusNode!,
              ))
          .toList(),
    );
  }

  KeyboardActionForm({
    Key? key,
    required this.items,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormBuilder(
      onChanged: () {
        ref.read(formChangedProvider.notifier).state = true;
      },
      key: _formKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return KeyboardActions(
            overscroll: 100,
            config: _buildConfig(context, ref),
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
                          Consumer(
                            builder: (context, ref, child) {
                              final formChanged =
                                  ref.watch(formChangedProvider);
                              return ElevatedButton(
                                onPressed: formChanged
                                    ? () {
                                        if (_formKey.currentState!
                                            .saveAndValidate(
                                                autoScrollWhenFocusOnInvalid:
                                                    true)) {
                                          Map<String, dynamic> formData =
                                              _formKey.currentState!.value;
                                          onSave.call(formData);
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    : null, // disable button when there's no change in form
                                child: Text('Update'.tr()),
                              );
                            },
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
