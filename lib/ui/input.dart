import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class AppInput extends StatelessWidget {
  final String? placeholder;
  final String? value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final TextStyle? style;
  final EdgeInsets? contentPadding;

  const AppInput({
    super.key,
    this.placeholder,
    this.value,
    this.onChanged,
    this.onTap,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.controller,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.style,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: maxLines == 1 ? 40.0 : null, // h-10
          constraints: maxLines != 1 ? const BoxConstraints(minHeight: 40.0) : null,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            initialValue: controller == null ? value : null,
            onChanged: onChanged,
            onTap: onTap,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: style ?? TextStyle(
              fontSize: 16.0, // text-base on mobile
              color: AppColors.foreground,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppColors.mutedForeground, // placeholder:text-muted-foreground
                fontSize: 16.0,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: contentPadding ?? const EdgeInsets.symmetric(
                horizontal: 12.0, // px-3
                vertical: 8.0,    // py-2
              ),
              filled: true,
              fillColor: AppColors.background, // bg-background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.0), // rounded-md
                borderSide: BorderSide(
                  color: AppColors.border, // border-input
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.0),
                borderSide: BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.0),
                borderSide: BorderSide(
                  color: AppColors.ring, // focus-visible:ring-ring
                  width: 2.0, // focus-visible:ring-2
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.0),
                borderSide: BorderSide(
                  color: AppColors.destructive,
                  width: 1.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.0),
                borderSide: BorderSide(
                  color: AppColors.destructive,
                  width: 2.0,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.0),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
              errorText: errorText,
              errorStyle: TextStyle(
                color: AppColors.destructive,
                fontSize: 12.0,
              ),
              counterText: maxLength != null ? null : "",
            ),
          ),
        ),
      ],
    );
  }
}

// Specialized input types
class EmailInput extends AppInput {
  const EmailInput({
    super.key,
    super.placeholder = '이메일을 입력하세요',
    super.value,
    super.onChanged,
    super.controller,
    super.focusNode,
    super.enabled,
    super.errorText,
  }) : super(
          keyboardType: TextInputType.emailAddress,
        );
}

class PasswordInput extends AppInput {
  const PasswordInput({
    super.key,
    super.placeholder = '비밀번호를 입력하세요',
    super.value,
    super.onChanged,
    super.controller,
    super.focusNode,
    super.enabled,
    super.errorText,
  }) : super(
          obscureText: true,
        );
}

class NumberInput extends StatelessWidget {
  final String placeholder;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final String? errorText;

  const NumberInput({
    super.key,
    this.placeholder = '숫자를 입력하세요',
    this.value,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      placeholder: placeholder,
      value: value,
      onChanged: onChanged,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      errorText: errorText,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}

class SearchInput extends AppInput {
  const SearchInput({
    super.key,
    super.placeholder = '검색어를 입력하세요',
    super.value,
    super.onChanged,
    super.controller,
    super.focusNode,
    super.enabled,
    super.errorText,
  }) : super(
          keyboardType: TextInputType.text,
          prefixIcon: const Icon(Icons.search, size: 16),
        );
}

class TextAreaInput extends AppInput {
  const TextAreaInput({
    super.key,
    super.placeholder = '내용을 입력하세요',
    super.value,
    super.onChanged,
    super.controller,
    super.focusNode,
    super.enabled,
    super.errorText,
    int maxLines = 5,
    int minLines = 3,
  }) : super(
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: TextInputType.multiline,
        );
} 