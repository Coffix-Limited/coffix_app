import 'package:coffix_app/core/constants/colors.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/services/log_service.dart';
import 'package:coffix_app/core/theme/typography.dart';
import 'package:coffix_app/core/utils/time_utils.dart';
import 'package:coffix_app/features/auth/data/model/user.dart';
import 'package:coffix_app/features/auth/logic/auth_cubit.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:coffix_app/features/profile/logic/profile_cubit.dart';
import 'package:coffix_app/features/stores/data/model/store.dart';
import 'package:coffix_app/features/stores/logic/store_cubit.dart';
import 'package:coffix_app/presentation/atoms/app_button.dart';
import 'package:coffix_app/presentation/atoms/app_date_field.dart';
import 'package:coffix_app/presentation/atoms/app_dropdown.dart';
import 'package:coffix_app/presentation/atoms/app_field.dart';
import 'package:coffix_app/presentation/atoms/app_loading.dart';
import 'package:coffix_app/presentation/atoms/app_notification.dart';
import 'package:coffix_app/presentation/organisms/app_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

class PersonalInfoPage extends StatelessWidget {
  static String route = 'personal_info_route';
  const PersonalInfoPage({super.key, required this.canBack});

  /// [canBack] is used to determine if the user can go back to the previous page.
  final bool canBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ProfileCubit>(),
      child: PersonalInfoView(canBack: canBack),
    );
  }
}

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({super.key, required this.canBack});

  final bool canBack;

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _onSave() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _formKey.currentState?.value;
      LogService().updateProfile();
      context.read<ProfileCubit>().updateProfile(
        firstName: formValues?['firstName'],
        lastName: formValues?['lastName'],
        nickName: formValues?['nickname'],
        mobile: formValues?['mobile'],
        birthday: formValues?['birthDate'],
        suburb: formValues?['suburb'],
        city: formValues?['city'],
        preferredStoreId: formValues?['preferredStoreId'],
        getPurchaseInfoByMail:
            formValues?['getPurchaseInfoByMail'], // notifications
        getPromotions: formValues?['getPromotions'], // promotions
        allowWinACoffee: formValues?['allowWinACoffee'], // purchase messages
        allowWithdrawBalance:
            formValues?['allowWithdrawBalance'], // none for now
      );
    }
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    AppUser? user,
    List<Store> stores,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField<String>(
          name: 'email',
          label: 'Email',
          hintText: 'Email',
          readOnly: true,
          isHorizontalAlign: true,
        ),
        const SizedBox(height: AppSizes.lg),
        AppField<String>(
          name: 'firstName',
          label: 'First Name',
          hintText: 'Enter first name',
          isRequired: true,
          isHorizontalAlign: true,
          maxLength: 50,
          onChanged: (val) {
            _formKey.currentState?.fields["nickname"]?.didChange(val);
          },
        ),
        const SizedBox(height: AppSizes.lg),
        AppField<String>(
          name: 'lastName',
          label: 'Last Name',
          hintText: 'Enter last name',
          isRequired: true,
          isHorizontalAlign: true,
          maxLength: 50,
        ),
        const SizedBox(height: AppSizes.lg),
        AppField<String>(
          name: 'nickname',
          label: 'Nick Name',
          hintText: 'Enter nickname',
          isRequired: true,
          isHorizontalAlign: true,
          maxLength: 50,
        ),
        const SizedBox(height: AppSizes.lg),
        AppField<String>(
          name: 'mobile',
          label: 'Mobile',
          hintText: 'Enter mobile',
          keyboardType: TextInputType.phone,
          isRequired: true,
          isHorizontalAlign: true,
          maxLength: 20,
        ),
        const SizedBox(height: AppSizes.lg),
        AppDateField(
          hintText: "Birthdate",
          name: "birthDate",
          label: "Date of Birth",
          firstDate: DateTime(1900),
          lastDate: TimeUtils.now(),
          initialDate: user?.birthday,
          isHorizontalAlign: true,
        ),
        Row(
          children: [
            SizedBox(width: 140.0),
            Expanded(
              child: Text(
                "You might get something for your birthday ",
                style: AppTypography.body3XS,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        AppField<String>(
          name: 'suburb',
          label: 'Suburb',
          hintText: 'Enter suburb',
          isHorizontalAlign: true,
        ),
        const SizedBox(height: AppSizes.lg),
        AppField<String>(
          name: 'city',
          label: 'City',
          hintText: 'Enter city',
          isRequired: true,
          isHorizontalAlign: true,
        ),
        const SizedBox(height: AppSizes.lg),
        AppDropdown<Store, String>(
          isHorizontalAlign: true,
          name: 'preferredStoreId',
          label: 'Preferred store',
          hintText: 'Select preferred store',
          isRequired: true,
          options: stores,
          itemLabel: (Store store) => store.name ?? "",
          itemValue: (Store store) => store.docId,
        ),
        const SizedBox(height: AppSizes.xxl),
        Text(
          'Settings',
          style: AppTypography.titleS.copyWith(
            color: AppColors.textBlackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        FormBuilderSwitch(
          name: 'getPurchaseInfoByMail',
          title: Text(
            'Receive notifications',
            style: theme.textTheme.bodyMedium,
          ),
          activeColor: AppColors.white,
          activeTrackColor: AppColors.success,
          inactiveTrackColor: AppColors.white,
          inactiveThumbColor: AppColors.primary,
        ),
        FormBuilderSwitch(
          name: 'getPromotions',
          title: Text(
            'Receive news and promotions',
            style: theme.textTheme.bodyMedium,
          ),
          activeColor: AppColors.white,
          activeTrackColor: AppColors.success,
          inactiveTrackColor: AppColors.white,
          inactiveThumbColor: AppColors.primary,
        ),
        FormBuilderSwitch(
          name: 'allowWinACoffee',
          title: Text(
            'Receive purchase messages',
            style: theme.textTheme.bodyMedium,
          ),
          activeColor: AppColors.white,
          activeTrackColor: AppColors.success,
          inactiveTrackColor: AppColors.white,
          inactiveThumbColor: AppColors.primary,
        ),
        const SizedBox(height: AppSizes.xxl),
        AppButton.primary(onPressed: _onSave, label: 'Save'),
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppUser? user = context.watch<AuthCubit>().state.maybeWhen(
      authenticated: (user) => user.user,
      orElse: () => null,
    );
    final List<Store> stores = context.watch<StoreCubit>().state.maybeWhen(
      loaded: (stores) => stores,
      orElse: () => [],
    );

    return PopScope(
      canPop: user?.finishedOnboarding == true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Account',
            style: AppTypography.titleXL.copyWith(
              color: AppColors.textBlackColor,
            ),
          ),
          leading: user?.finishedOnboarding == true
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                )
              : const SizedBox.shrink(),
        ),
        body: SingleChildScrollView(
          padding: AppSizes.defaultPadding,
          child: FormBuilder(
            initialValue: {
              'email': user?.email,
              "firstName": user?.firstName,
              "lastName": user?.lastName,
              "nickname": user?.nickName,
              "mobile": user?.mobile,
              "birthDate": user?.birthday,
              "suburb": user?.suburb,
              "city": user?.city,
              "preferredStoreId": user?.preferredStoreId,
              "getPurchaseInfoByMail": user?.getPurchaseInfoByMail,
              "getPromotions": user?.getPromotions,
              "allowWinACoffee": user?.allowWinACoffee,
              "allowWithdrawBalance": user?.allowWithdrawBalance,
            },
            key: _formKey,
            child: BlocConsumer<ProfileCubit, ProfileState>(
              listener: (context, state) {
                state.mapOrNull(
                  success: (state) {
                    AppNotification.show(
                      context,
                      "Profile updated successfully!",
                    );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (context.mounted) context.goNamed(HomePage.route);
                    });
                  },
                  error: (state) =>
                      AppError(title: "Error", subtitle: state.message),
                );
              },
              builder: (context, state) {
                return state.when(
                  initial: () => _buildForm(context, theme, user, stores),
                  loading: () => AppLoading(),
                  success: () => _buildForm(context, theme, user, stores),
                  error: (message) => _buildForm(context, theme, user, stores),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
