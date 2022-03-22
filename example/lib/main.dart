// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:stripe_terminal/models/configurations/bluetooth_connection_configuration.dart';
import 'package:stripe_terminal/models/configurations/bluetooth_discovery_configuration.dart';
import 'package:stripe_terminal/models/configurations/connection_token_provider_configuration.dart';
import 'package:stripe_terminal/models/stripe_reader.dart';
import 'package:stripe_terminal/stripe_terminal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StripeReader? connectedReader;
  bool isLoadingReaderConnection = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    StripeTerminal.setup();

    try {
      StripeTerminal.setupConnectionTokenProvider(
        config: ConnectionTokenProviderConfiguration(
          backendBaseUrl: 'https://test1-ucallz.azurewebsites.net',
          requestUrl: '/Api/ConnectionToken',
          tokenKeyInJson: 'Data',
          userAutherizationToken:
              'ETzLL8flFMUXsHCUGi2xrokKB8iV_Yt0tudK54N6c6WTDsgJWHMVtKAbq2J9oqJ0vyGQzZ6FdN3mnQw8Dhl_i8B5c2szocwCuZngrkfSPrhyKiffr7CE8t_kez6uKAE_zcKcW4BhxRKCjFXPISXiZ5gxIUXtCeqdOhrA9msLhkKni_v5A5Ifhw_rLClbaThBvSRl-DBokAZZGEwxmkY4I1vYTTQ1bz7UpPNWF-GHP_wwR6Ci2fEai96c-DRKBOUpvliF7PBWG15EeAJmou88Z2dOQz7XoUIepk2D3RMzsGz_4dVY_8hrnw_plgMje9DT_etRvn6QS3StV0zDwGcj9xzzqOBXHnpFY4FneWaSGMf12lW9LVq_XHpq9obPOT7x07OZhsq5HUcGO6fpO3_lNiTGzrBlNBog0FUJJ7MZuVobEv-LajJQC6_oBqnitrXNb5ddVJKe4b7ivvCD8gruNDdTGM2K69_CiXzFESnVS3fYr5pcAu6RXOwIvhFUACmKl9jKa_9UXVSDObvjKMew0goR5BfqQr9TZkIS-DQmJA4',
        ),
      );
    } on PlatformException catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MaterialButton(
                child: const Text('Discvoer'),
                color: Colors.blue,
                onPressed: () async {
                  try {
                    await StripeTerminal.discoverReaders(
                      config: BluetoothDiscoveryConfiguration(
                        simulated: false,
                      ),
                    );
                  } catch (e) {
                    print(e);
                    print('');
                  }
                },
              ),
              const SizedBox(height: 50),
              connectedReader == null
                  ? StreamBuilder(
                      stream: StripeTerminal.didUpdateDiscoveredReader,
                      builder: (context, snapshot) {
                        if (isLoadingReaderConnection) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasData) {
                          final readers = snapshot.data as List<StripeReader>;
                          if (readers.isEmpty) {
                            return const Text('No readers detected');
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: readers.length,
                            itemBuilder: (context, index) {
                              final currReader = readers[index];

                              return ListTile(
                                title: Text(currReader.serialNumber),
                                tileColor: Colors.grey[100],
                                onTap: () async {
                                  setState(() {
                                    isLoadingReaderConnection = true;
                                  });

                                  try {
                                    await StripeTerminal.connectBluetoothReader(
                                      reader: currReader,
                                      config: BluetoothConnectionConfiguration(
                                        locationId: 'tml_EiQJwXfwQkiMuF',
                                      ),
                                    );

                                    setState(() {
                                      connectedReader = currReader;
                                    });
                                  } catch (e) {
                                    print(e);
                                  }

                                  setState(() {
                                    isLoadingReaderConnection = false;
                                  });
                                },
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const Divider();
                            },
                          );
                        } else {
                          return const Text('Doesnt have data');
                        }
                      },
                    )
                  : Text('Connected to reader: ${connectedReader!.serialNumber}'),
              const SizedBox(height: 50),
              if (connectedReader != null)
                MaterialButton(
                  child: const Text('Charge 100'),
                  color: Colors.blue,
                  onPressed: () async {
                    const paymentIntent = 'YOUR_PAYMENT_INTENT_HERE';

                    try {
                      await StripeTerminal.charge(paymentIntent: paymentIntent);

                      print("Payment success: $paymentIntent");
                    } catch (e) {
                      print(e);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}