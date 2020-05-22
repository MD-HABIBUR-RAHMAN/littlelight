package main

import (
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/plugins/path_provider"
	"github.com/go-flutter-desktop/plugins/shared_preferences"
	"github.com/nealwon/go-flutter-plugin-sqlite"
)

var options = []flutter.Option{
	flutter.WindowInitialDimensions(1200, 700),
	flutter.AddPlugin(&shared_preferences.SharedPreferencesPlugin{
		VendorName:      "me.markezine",
		ApplicationName: "littlelight",
	}),
	flutter.AddPlugin(&path_provider.PathProviderPlugin{
		VendorName:      "me.markezine",
		ApplicationName: "littlelight",
	}),
	flutter.AddPlugin(sqflite.NewSqflitePlugin(
		"me.markezine",
		"littlelight",
	)),
}
