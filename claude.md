# keyboard_action_form - Flutter Form Helper Library

## Project Overview

**keyboard_action_form** is a Flutter helper library (v0.7.0) that provides form widgets with integrated keyboard action handling for iOS devices. It wraps `flutter_form_builder` components to add sophisticated keyboard navigation and action buttons, specifically designed for mobile-first form experiences.

**Repository:** https://github.com/Sistemium/keyboard_action_form.git
**Version:** 0.7.0
**Dart SDK:** >=3.0.6 <4.0.0

## Core Purpose

Provide a seamless form input experience with:
- Navigation between form fields using keyboard "Next/Previous" buttons
- Configurable save/delete actions on keyboard toolbar
- Form state management with clear/disabled button logic
- Easy integration with flutter_form_builder ecosystem
- Support for multiline text input with auto-expanding text fields
- Auto-appearing clear buttons for text inputs
- Typeahead/autocomplete integration with form state

## Key Dependencies

```yaml
dependencies:
  flutter_form_builder: ^10.2.0      # Base form field management
  keyboard_actions: ^4.2.0           # iOS keyboard toolbar
  flutter_typeahead: ^5.2.0          # Dropdown/autocomplete
  form_builder_extra_fields: ^12.1.0 # Additional field types
  form_builder_validators: ^11.2.0   # Validators
  easy_localization: ^3.0.8          # Multi-language
  cooldown_button:                   # Delete confirmation
    git:
      url: https://github.com/Sistemium/cooldown_button.git
```

## Architecture Overview

```
KeyboardActionForm (Container)
│
├─ FormBuilder (state manager, GlobalKey)
│  │
│  └─ KeyboardActions (iOS toolbar)
│     │
│     ├─ ConstrainedBox (prevent keyboard overlap)
│     │  │
│     │  ├─ FormBuilderTextFieldWrapper
│     │  │  └─ ValueListenableBuilder
│     │  │     └─ TextEditingController + Clear button
│     │  │
│     │  ├─ FormBuilderTypeAheadWrapper
│     │  │  └─ ValueListenableBuilder
│     │  │     └─ TypeAheadController
│     │  │
│     │  └─ [More fields...]
│     │
│     └─ Action Buttons Row
│        ├─ Cancel (always enabled)
│        ├─ Delete (if onDelete provided)
│        └─ Save (enabled based on form state)
```

## Main Components

### 1. KeyboardActionForm

**Purpose:** Main container widget that orchestrates form fields with iOS keyboard toolbar.

**Key Features:**
- Manages FocusNode instances for all form fields
- Configures iOS keyboard toolbar with Next/Previous/Done buttons
- Provides Cancel/Save/Delete action buttons
- Monitors form state changes
- Prevents keyboard from covering form fields

**Usage:**
```dart
KeyboardActionForm(
  length: 5,  // Number of form fields
  actionLabel: 'Save',
  enableActionWhenNoChanges: true,

  itemsCallback: (List<FocusNode> nodes) => [
    FormBuilderTextField(focusNode: nodes[0], ...),
    FormBuilderTextFieldWrapper(focusNode: nodes[1], ...),
    FormBuilderTypeAheadWrapper(focusNode: nodes[2], ...),
    // ... more fields
  ],

  onSave: (Map<String, dynamic> formData) async {
    await saveToBackend(formData);
  },

  onDelete: () async {
    await deleteRecord();
  },
)
```

**Parameters:**
- `length: int` - Number of form fields (FocusNodes created)
- `itemsCallback: Function(List<FocusNode>)` - Builds form field widgets
- `actionLabel: String` - Text for save button
- `onSave: Function(Map<String, dynamic>)` - Save handler (required)
- `onDelete: Function()?` - Optional delete handler
- `enableActionWhenNoChanges: bool` - Enable save without changes (default: true)

### 2. FormBuilderTextFieldWrapper

**Purpose:** Enhanced text input field with built-in clear button functionality.

**Key Features:**
- Auto-appearing clear button (suffix icon) when field has text
- ValueNotifier pattern for reactive UI updates
- Independent TextEditingController management
- Full multiline support
- Value transformation on save

**Multiline Configuration:**
```dart
FormBuilderTextFieldWrapper(
  focusNode: nodes[1],
  name: 'description',
  initialValue: 'Start typing...',

  // KEY: Enable multiline mode
  maxLines: null,                         // null = unlimited lines
  keyboardType: TextInputType.multiline, // Keyboard shows return key

  decoration: InputDecoration(
    labelText: 'Description',
  ),

  validator: FormBuilderValidators.required(),

  onChanged: (value) {
    // Called on each keystroke
  },
)
```

**Parameters:**
- `focusNode: FocusNode` - Navigation focus point (required)
- `name: String` - Form field identifier (required)
- `initialValue: String?` - Pre-filled text
- `decoration: InputDecoration` - UI styling (required)
- `keyboardType: TextInputType?` - Keyboard type (set to `multiline` for multiline)
- `maxLines: int?` - Line limit (`null` = unlimited, enables multiline)
- `validator: FormFieldValidator<String>?` - Validation logic
- `enabled: bool` - Enable/disable field (default: true)
- `valueTransformer: ValueTransformer<String?>?` - Value transformation
- `onChanged: ValueChanged?` - Change callback

**Internal Implementation:**
```dart
// Uses ValueNotifier to reactively show/hide clear button
late TextEditingController textEditingController;
late ValueNotifier<bool> _controllerTextNotEmptyNotifier;

textEditingController.addListener(() {
  _controllerTextNotEmptyNotifier.value = textEditingController.text.isNotEmpty;
});

// Clear button appears when field has text
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
```

### 3. FormBuilderTypeAheadWrapper<T>

**Purpose:** Wraps flutter_typeahead with form_builder integration and clear button functionality.

**Key Features:**
- Programmatic selection via TypeAheadController
- Auto-clear button when text entered
- Required field validation
- Transformer pattern for display text
- Generic type support

**Usage:**
```dart
FormBuilderTypeAheadWrapper<Map<String, dynamic>>(
  name: 'service_point',
  initialValue: null,
  enabled: true,
  validate: true,
  focusNode: nodes[2],

  selectionToTextTransformer: (point) => point?['address'] ?? '',

  decoration: InputDecoration(labelText: 'Select Service Point'),

  suggestionsCallback: (pattern) async {
    return await fetchServicePoints(pattern);
  },

  itemBuilder: (context, suggestion) => ListTile(
    title: Text(suggestion['address']),
  ),

  onChanged: (selectedPoint) {
    print('Selected: ${selectedPoint['address']}');
  },
)
```

**Parameters:**
- `name: String` - Field identifier (required)
- `initialValue: T` - Default selected item (required)
- `focusNode: FocusNode` - Navigation focus (required)
- `selectionToTextTransformer: Function(T) -> String` - Convert item to display text (required)
- `suggestionsCallback: Function(String) -> Future<List<T>>` - Fetch suggestions (required)
- `itemBuilder: Function(BuildContext, T) -> Widget` - Render suggestion (required)
- `decoration: InputDecoration` - UI styling (required)
- `enabled: bool` - Enable/disable (default: true)
- `validate: bool` - Require selection (default: true)
- `controller: TypeAheadController<T>?` - External state control
- `onChanged: ValueChanged<T?>?` - Selection change callback

**TypeAheadController:**
```dart
class TypeAheadController<T> {
  void updateValue(T newValue, String formName, BuildContext context) {
    // Updates both widget state and form state
    _state?.updateValue(newValue);
    final formBuilder = FormBuilder.of(context);
    formBuilder?.patchValue({formName: newValue});
    formBuilder?.fields[formName]?.validate();
  }
}
```

## Multiline Text Field Implementation

### Version History

- **v0.6.8** (April 29, 2025) - Added `maxLines` parameter to FormBuilderTextFieldWrapper
- **v0.7.0** (Current) - Full multiline support with keyboard actions integration

### Proper Multiline Configuration

To implement multiline text fields correctly:

**1. Set Both Parameters:**
```dart
FormBuilderTextFieldWrapper(
  focusNode: nodes[1],
  name: 'description',
  maxLines: null,                         // REQUIRED: null = unlimited lines
  keyboardType: TextInputType.multiline, // REQUIRED: enables return key
  decoration: InputDecoration(labelText: 'Description'),
)
```

**2. iOS Keyboard Behavior:**
- Return key creates a new line (does NOT submit form)
- Keyboard toolbar still shows "Next" and "Done" buttons
- Users tap "Done" to finish editing or tap outside field
- Field auto-expands as user types

**3. Height Expansion:**
- With `maxLines: null`, the text field expands vertically
- Consider wrapping KeyboardActionForm in SingleChildScrollView if form is long
- Keyboard toolbar provides 100 pixels of overscroll space

**4. Parameter Passing:**
```dart
// FormBuilderTextFieldWrapper passes through to FormBuilderTextField
FormBuilderTextField(
  keyboardType: widget.keyboardType,    // Passes TextInputType.multiline
  maxLines: widget.maxLines,             // Passes null for unlimited
)
```

### Common Mistakes to Avoid

❌ **WRONG:**
```dart
FormBuilderTextFieldWrapper(
  maxLines: 5,  // BAD: Limits to 5 lines
  // Missing keyboardType
)
```

❌ **WRONG:**
```dart
FormBuilderTextFieldWrapper(
  minLines: 3,  // ERROR: Parameter doesn't exist
  maxLines: null,
)
```

✅ **CORRECT:**
```dart
FormBuilderTextFieldWrapper(
  maxLines: null,                         // Unlimited lines
  keyboardType: TextInputType.multiline, // Multiline keyboard
)
```

## Form State Integration

### Accessing Form Data

```dart
// Access form state anywhere in widget tree
final formBuilder = FormBuilder.of(context);

// Get all form data
Map<String, dynamic> data = formBuilder.value;

// Patch specific fields
formBuilder.patchValue({'field_name': 'new_value'});

// Validate specific field
formBuilder.fields['field_name']?.validate();

// Save and validate all
if (formBuilder.saveAndValidate()) {
  final data = formBuilder.value;
}
```

### Value Transformation

```dart
FormBuilderTextFieldWrapper(
  name: 'price',
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  valueTransformer: (String? text) => num.tryParse(text ?? ''),
)

// Form value will contain num type, not String
```

### Cross-Field Validation

```dart
FormBuilderField<dynamic>(
  name: 'service_description_validator',
  builder: (field) => InputDecorator(
    decoration: InputDecoration(
      errorText: field.errorText,
      border: InputBorder.none,
    ),
    child: Container(),
  ),
  validator: (_) {
    final hasDescription = descriptionState.trim().isNotEmpty;
    final hasService = serviceId != null;
    if (!hasDescription && !hasService) {
      return 'Either Service or Description is required';
    }
    return null;
  },
)
```

## iOS Keyboard Toolbar Features

### Configuration

```dart
KeyboardActions(
  overscroll: 100,  // Space above keyboard
  config: KeyboardActionsConfig(
    keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
    keyboardBarColor: Colors.grey[200],
    nextFocus: true,  // Enable field navigation
    actions: focusNodes
        .map((e) => KeyboardActionsItem(focusNode: e))
        .toList(),
  ),
  child: Form(...),
)
```

### Features:
- **Previous Button** (arrow up) - Navigate to previous field
- **Next Button** (arrow down) - Navigate to next field
- **Done Button** (on last field) - Closes keyboard
- **Platform Support** - iOS, Android, Web
- **Auto-hide** - Only shows on platforms that need it
- **Smart Focus** - Automatically focuses next field, skips disabled fields

## Localization Support

Uses `easy_localization` (v3.0.8):

```dart
'Cancel'.tr()
'Delete'.tr()
'Field is required'.tr()
'No Items Found!'.tr()
```

Library supports multiple languages via easy_localization configuration in consuming app.

## Best Practices

### 1. FocusNode Management
- Let KeyboardActionForm manage FocusNode instances
- Use nodes from itemsCallback parameter
- Don't create FocusNodes manually

### 2. Form Length
- Set `length` parameter to match number of form fields
- Count all fields that need keyboard navigation
- Don't count FormBuilderField validators

### 3. Multiline Fields
- Always set both `maxLines: null` and `keyboardType: TextInputType.multiline`
- Don't try to use `minLines` (parameter doesn't exist)
- Consider form height for proper scrolling

### 4. Validation
- Use FormBuilderValidators for common cases
- Implement custom validators for complex logic
- Use FormBuilderField for cross-field validation

### 5. Value Transformation
- Use `valueTransformer` for type conversion
- Transform happens only on form save
- Display value remains as string during editing

### 6. TypeAhead Fields
- Implement async suggestionsCallback for responsive search
- Provide meaningful itemBuilder for clear UI
- Use selectionToTextTransformer for display text

## Complete Example

```dart
class EditServiceTask extends StatefulWidget {
  final Map<String, dynamic>? serviceTask;

  const EditServiceTask({this.serviceTask});

  @override
  State<EditServiceTask> createState() => _EditServiceTaskState();
}

class _EditServiceTaskState extends State<EditServiceTask> {
  String _descriptionState = '';
  String? _selectedServiceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: KeyboardActionForm(
          length: 5,
          actionLabel: 'Save',

          itemsCallback: (List<FocusNode> nodes) => [
            // Date picker
            FormBuilderDateTimePicker(
              focusNode: nodes[0],
              name: 'date',
              inputType: InputType.date,
              decoration: InputDecoration(labelText: 'Date'),
              validator: FormBuilderValidators.required(),
            ),

            // Multiline description
            FormBuilderTextFieldWrapper(
              focusNode: nodes[1],
              name: 'description',
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(labelText: 'Description'),
              onChanged: (_) {
                setState(() {
                  _descriptionState = FormBuilder.of(context)
                      ?.fields['description']?.value ?? '';
                });
              },
            ),

            // Service point typeahead
            FormBuilderTypeAheadWrapper<Map<String, dynamic>?>(
              focusNode: nodes[2],
              name: 'point',
              initialValue: null,
              selectionToTextTransformer: (s) => s?['address'] ?? '',
              suggestionsCallback: (pattern) async {
                return await fetchServicePoints(pattern);
              },
              itemBuilder: (_, suggestion) => ListTile(
                title: Text(suggestion?['address'] ?? ''),
              ),
              decoration: InputDecoration(labelText: 'Service Point'),
            ),

            // Service typeahead
            FormBuilderTypeAheadWrapper<Map<String, dynamic>?>(
              focusNode: nodes[3],
              name: 'service',
              initialValue: null,
              selectionToTextTransformer: (s) => s?['name'] ?? '',
              suggestionsCallback: (pattern) async {
                return await fetchArticles(pattern);
              },
              itemBuilder: (_, suggestion) =>
                  ListTile(title: Text(suggestion?['name'] ?? '')),
              decoration: InputDecoration(labelText: 'Service'),
              onChanged: (article) {
                setState(() {
                  _selectedServiceId = article?['id'];
                });
              },
            ),

            // Price
            FormBuilderTextFieldWrapper(
              focusNode: nodes[4],
              name: 'price',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Price'),
              valueTransformer: (String? text) => num.tryParse(text ?? ''),
            ),

            // Cross-field validator
            FormBuilderField<dynamic>(
              name: 'validator',
              builder: (field) => InputDecorator(
                decoration: InputDecoration(
                  errorText: field.errorText,
                  border: InputBorder.none,
                ),
                child: Container(),
              ),
              validator: (_) {
                final hasDesc = _descriptionState.trim().isNotEmpty;
                final hasService = _selectedServiceId != null;
                if (!hasDesc && !hasService) {
                  return 'Either Service or Description required';
                }
                return null;
              },
            ),
          ],

          onSave: (formData) async {
            final date = formData['date'] as DateTime?;
            final description = formData['description'] as String?;
            final point = formData['point'] as Map<String, dynamic>?;
            final service = formData['service'] as Map<String, dynamic>?;
            final price = formData['price'] as num?;

            await saveToBackend({
              'date': date?.toIso8601String(),
              'description': description,
              'servicePointId': point?['id'],
              'serviceId': service?['id'],
              'price': price,
            });
          },
        ),
      ),
    );
  }
}
```

## Testing Checklist

When implementing forms with keyboard_action_form:

- [ ] Set correct `length` matching number of form fields
- [ ] Provide all required FocusNode instances from itemsCallback
- [ ] For multiline: Set both `maxLines: null` and `keyboardType: TextInputType.multiline`
- [ ] Test keyboard toolbar appears on iOS
- [ ] Verify Next button navigates between fields
- [ ] Verify Done button closes keyboard
- [ ] Test clear button appears/disappears
- [ ] Test save button enables/disables correctly
- [ ] Test delete confirmation (if using onDelete)
- [ ] Verify validators work correctly
- [ ] Test cross-field validation
- [ ] Test value transformers
- [ ] Test TypeAhead suggestions load
- [ ] Test on both iOS and Android
- [ ] Verify multiline field expands as text entered

## Summary

keyboard_action_form is a production-grade Flutter library that elegantly bridges flutter_form_builder with iOS keyboard navigation. The three main classes work together to provide:

1. **Automatic keyboard toolbar** with Next/Previous/Done navigation
2. **Smart clear buttons** that appear/disappear based on field state
3. **Full multiline text support** via maxLines: null + TextInputType.multiline
4. **Typeahead integration** with external state control
5. **Form state management** with save/delete actions
6. **Localization support** via easy_localization
7. **Cross-field validation** capabilities
8. **Value transformation** for type conversion

The library is mature at v0.7.0 with full multiline support since v0.6.8, making it suitable for complex production forms.
