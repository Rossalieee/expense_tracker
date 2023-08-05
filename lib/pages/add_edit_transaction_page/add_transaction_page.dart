import 'dart:io';

import 'package:expense_tracker/app_spacers.dart';
import 'package:expense_tracker/expense_category.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/pages/add_edit_transaction_page/add_transaction_state.dart';
import 'package:expense_tracker/pages/add_edit_transaction_page/bloc/add_transaction_cubit.dart';
import 'package:expense_tracker/pages/add_edit_transaction_page/choice_chips.dart';
import 'package:expense_tracker/validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddTransactionCubit(),
      child: _AddTransactionPage(),
    );
  }
}

class _AddTransactionPage extends StatelessWidget {
  _AddTransactionPage();

  final _formKey = GlobalKey<FormState>();

  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      builder: (context, state) {
        final cubit = context.read<AddTransactionCubit>();

        var title = '';
        var description = '';
        var amount = 0.0;

        void submitForm() {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();

            objectbox.addTransaction(
              title: title,
              description: description.isEmpty ? null : description,
              amount: amount,
              date: state.date,
              isIncome: state.isIncome,
              photo: state.photo,
              expenseCategory: state.expenseCategory,
            );

            _formKey.currentState!.reset();

            cubit.clearPhoto();
          }
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Add Transaction'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  AppSpacers.h5,
                  _AddTransactionInput(
                    label: 'Title',
                    onSaved: (value) => title = value!,
                    validator: validateTitle,
                  ),
                  AppSpacers.h12,
                  _AddTransactionInput(
                    label: 'Description',
                    onSaved: (value) => description = value!,
                  ),
                  AppSpacers.h12,
                  _AddTransactionInput(
                    label: 'Amount',
                    onSaved: (value) => amount = double.parse(value!),
                    isNumeric: true,
                    validator: validateAmount,
                  ),
                  AppSpacers.h12,
                  Center(
                    child: Wrap(
                      spacing: 6,
                      children: choiceChips(
                        context,
                        state,
                        null,
                        isEditTransactionPage: false,
                      ),
                    ),
                  ),
                  AppSpacers.h5,
                  Visibility(
                    visible: cubit.state.type == TransactionType.expense,
                    child: ExpenseCategoryDropdown(cubit: cubit),
                  ),
                  AppSpacers.h15,
                  OutlinedButton(
                    onPressed: () {
                      picker.pickImage(source: ImageSource.gallery).then(
                            (value) => cubit.selectPhoto(value!.path),
                          );
                    },
                    child: const Text('Add photo'),
                  ),
                  if (cubit.state.photo != null)
                    ShowPhoto(cubit: cubit)
                  else
                    AppSpacers.h0,
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Transaction Date'),
                    subtitle: Text(DateFormat.yMMMd().format(cubit.state.date)),
                    onTap: () => showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    ).then(cubit.selectDate),
                  ),
                  AppSpacers.h15,
                  ElevatedButton(
                    onPressed: submitForm,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      minimumSize: const Size(60, 45),
                    ),
                    child: const Text('Save Transaction'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddTransactionInput extends StatelessWidget {
  const _AddTransactionInput({
    required this.label,
    required this.onSaved,
    this.validator,
    this.isNumeric = false,
  });

  final String label;
  final bool isNumeric;
  final void Function(String?) onSaved;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            )
          : TextInputType.text,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        contentPadding: const EdgeInsets.all(8),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }
}

class ShowPhoto extends StatelessWidget {
  const ShowPhoto({
    required this.cubit,
    super.key,
  });

  final AddTransactionCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          alignment: Alignment.center,
          height: 240,
          child: Image.file(
            File(cubit.state.photo!),
            fit: BoxFit.fill,
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: IconButton(
            icon: const Icon(Icons.cancel_outlined),
            onPressed: cubit.clearPhoto,
          ),
        )
      ],
    );
  }
}

class ExpenseCategoryDropdown extends StatelessWidget {
  const ExpenseCategoryDropdown({
    required this.cubit,
    super.key,
  });

  final AddTransactionCubit cubit;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      value: cubit.state.expenseCategory,
      hint: const Text('Expense Category'),
      isExpanded: true,
      onChanged: cubit.setExpenseCategory,
      validator: validateExpenseCategory,
      onSaved: cubit.setExpenseCategory,
      items: ExpenseCategory.values.map((e) {
        return DropdownMenuItem(
          value: e.name,
          child: Row(
            children: [
              Icon(e.icon),
              AppSpacers.w10,
              Text(e.name),
            ],
          ),
        );
      }).toList(),
    );
  }
}
