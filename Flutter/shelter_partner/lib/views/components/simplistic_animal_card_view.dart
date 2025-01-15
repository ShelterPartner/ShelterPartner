// Import statements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/animal_card_repository.dart';
import 'package:shelter_partner/view_models/animal_card_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/take_out_confirmation_view_model.dart';
import 'package:shelter_partner/views/components/add_log_view.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';
import 'package:shelter_partner/views/components/animal_card_image.dart';
import 'package:shelter_partner/views/components/put_back_confirmation_view.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';
import 'package:uuid/uuid.dart';
import 'package:icon_decoration/icon_decoration.dart';

class SimplisticAnimalCardView extends ConsumerStatefulWidget {
  final Animal animal;

  const SimplisticAnimalCardView({super.key, required this.animal});

  @override
  _SimplisticAnimalCardViewState createState() =>
      _SimplisticAnimalCardViewState();
}

/// Helper method to calculate time ago from a given DateTime
String _timeAgo(DateTime dateTime, bool inKennel) {
  final Duration difference = DateTime.now().difference(dateTime);

  if (difference.inDays > 8) {
    return '${(difference.inDays / 7).floor()} weeks${inKennel ? ' ago' : ''}';
  } else if (difference.inDays >= 1) {
    return '${difference.inDays} days${inKennel ? ' ago' : ''}';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} hours${inKennel ? ' ago' : ''}';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes} minutes${inKennel ? ' ago' : ''}';
  } else {
    return inKennel ? 'Just now' : '0 minutes';
  }
}

class _SimplisticAnimalCardViewState
    extends ConsumerState<SimplisticAnimalCardView>
    with TickerProviderStateMixin {
  bool _automaticPutBackHandled = false;

  late AnimationController _controller;
  late Animation<double> _curvedAnimation;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_automaticPutBackHandled) {
        final shelterDetails = ref.read(shelterDetailsViewModelProvider).value;

        if (shelterDetails != null) {
          final shelterSettings = shelterDetails.shelterSettings;
          final shelterId = shelterDetails.id;
          final animalType = widget.animal.species;

          final viewModel = AnimalCardViewModel(
            repository: AnimalRepository(),
            shelterId: shelterId,
            animalType: animalType,
            shelterSettings: shelterSettings,
          );

          viewModel.handleAutomaticPutBack(widget.animal);
        }
        _automaticPutBackHandled = true;
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2 seconds duration
    );

    // Non-linear progress curve: slow at first, speeding up later
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Listen for animation completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset the animation instantly
        _controller.reset();

        // Retrieve the latest animal state
        final currentAnimal = widget.animal;

        // Animation completed, show confirmation dialog
        if (currentAnimal.inKennel) {
          final accountDetails =
              ref.read(accountSettingsViewModelProvider).value;
          if (accountDetails != null &&
              (accountDetails.accountSettings!.requireName ||
                  accountDetails.accountSettings!.requireLetOutType)) {
            _showTakeOutConfirmationDialog();
          } else {
            ref
                .read(takeOutConfirmationViewModelProvider(widget.animal)
                    .notifier)
                .takeOutAnimal(
                    widget.animal,
                    Log(
                      id: const Uuid().v4().toString(),
                      type: '',
                      author: '',
                      authorID: '',
                      earlyReason: '',
                      startTime: Timestamp.now(),
                      endTime: widget.animal.logs.last.endTime,
                    ));
          }
        } else {
          _showPutBackConfirmationDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showTakeOutConfirmationDialog() async {
    // Show the custom confirmation widget using the ref object
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return TakeOutConfirmationView(
          animals: [widget.animal],
        );
      },
    );
  }

  Future<void> showErrorDialog(
      {required BuildContext context, required String message}) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPutBackConfirmationDialog() async {
    // Show the custom confirmation dialog using the helper
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return PutBackConfirmationView(
          animals: [widget.animal],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final shelterDetailsAsync = ref.watch(shelterDetailsViewModelProvider);

    // Determine if shelterID is available
    bool canInteract = false;
    shelterDetailsAsync.when(
      data: (shelter) {
        if (shelter != null && shelter.id.isNotEmpty) {
          canInteract = true;
        }
      },
      loading: () {
        canInteract = false;
      },
      error: (error, stack) {
        canInteract = false;
      },
    );

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        decoration: BoxDecoration(
          color: animal.inKennel
              ? Colors.lightBlue.shade100
              : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              // spreadRadius: 0.5,
              blurRadius: 1,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Animal image and interaction
              GestureDetector(
                onTapDown: canInteract
                    ? (_) {
                        setState(() {
                          isPressed = true;
                        });
                        _controller.forward();
                        HapticFeedback.mediumImpact();
                      }
                    : null,
                onTapUp: canInteract
                    ? (_) {
                        setState(() {
                          isPressed = false;
                        });
                        _controller.reverse();
                        HapticFeedback.lightImpact();
                      }
                    : null,
                onTapCancel: canInteract
                    ? () {
                        setState(() {
                          isPressed = false;
                        });
                        _controller.reverse();
                        HapticFeedback.lightImpact();
                      }
                    : null,
                child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: AnimalCardImage(
                        curvedAnimation: _curvedAnimation,
                        isPressed: isPressed,
                        animal: animal)),
              ),
              const SizedBox(width: 10),
              // Animal details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name, symbol, and menu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Check if the name contains multiple words
                                  final isSingleWord =
                                      !animal.name.contains(' ');

                                  if (isSingleWord) {
                                    // Used FittedBox for single-word names
                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        animal.name,
                                        style: const TextStyle(
                                          fontFamily: 'CabinBold',
                                          fontSize: 32.0,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      animal.name,
                                      style: const TextStyle(
                                        fontFamily: 'CabinBold',
                                        fontSize: 32.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      maxLines: 2,
                                    );
                                  }
                                },
                              ),
                            ),
                            PopupMenuButton<String>(
                              offset: const Offset(0, 40),
                              onSelected: (value) {
                                // Handle menu item selection
                                switch (value) {
                                  case 'Details':
                                    context.push('/enrichment/details',
                                        extra: animal);
                                    break;
                                  case 'Add Note':
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          AddNoteView(animal: animal),
                                    );
                                    break;
                                  case 'Add Log':
                                    showDialog(
                                        context: context,
                                        builder: (context) =>
                                            AddLogView(animal: animal));
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                final appUser = ref.read(appUserProvider);
                                final accountSettings = ref
                                    .read(accountSettingsViewModelProvider)
                                    .value;

                                final menuItems = {'Details', 'Add Note'};
                                if (appUser?.type == "admin" &&
                                    accountSettings!.accountSettings?.mode ==
                                        "Admin" &&
                                    animal.inKennel) {
                                  menuItems.add('Add Log');
                                }

                                return menuItems.map((String choice) {
                                  return PopupMenuItem<String>(
                                    value: choice,
                                    child: Text(choice),
                                  );
                                }).toList();
                              },
                              icon: const Icon(Icons.more_vert),
                            ),
                          ],
                        ),
                        // Location
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                animal.location,
                                style: TextStyle(
                                  fontFamily: 'CabinBold',
                                  fontSize: 25,
                                  color: Colors.grey.shade800,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),

                        // Last Let out
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _timeAgo(
                                  widget.animal.inKennel
                                      ? animal.logs.last.endTime.toDate()
                                      : animal.logs.last.startTime.toDate(),
                                  widget.animal.inKennel),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontFamily: 'CabinBold',
                              ),
                            ),
                            if (animal.symbol.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: _buildIcon(
                                    animal.symbol, animal.symbolColor),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildIcon(String symbol, String symbolColor) {
  IconData? iconData;

  switch (symbol) {
    case 'pets':
      iconData = Icons.pets;
      break;
    case 'location_on':
      iconData = Icons.location_on;
      break;
    case 'star':
      iconData = Icons.star;
      break;
    default:
      return const SizedBox.shrink(); // No icon for default case
  }

  return DecoratedIcon(
    icon: Icon(
      iconData,
      color: _parseColor(symbolColor),
      size: 24, // Original size
    ),

    // decoration: const IconDecoration(
    //   border: IconBorder(
    //     color: Colors.black,
    //     width: 0.75,
    //   )
    // ),
  );
}

Color _parseColor(String colorString) {
  switch (colorString.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'grey':
      return Colors.grey;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    default:
      return Colors.transparent; // Default case if color is not recognized
  }
}
