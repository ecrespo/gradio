/* This file is part of Gradio.
 *
 * Gradio is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Gradio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Gradio.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using GLib;

namespace Gradio {

	public class App : Gtk.Application {

		public static Settings settings;
		public static MainWindow window;
		public static AudioPlayer player;
		public static Library library;
		public static MPRIS mpris;
		public static ImageCache image_cache;

		private SearchProvider search_provider;
		private uint search_provider_id = 0;

		public App() {
			Object(application_id: "de.haeckerfelix.gradio", flags: ApplicationFlags.FLAGS_NONE);

			// Check for for internet access TODO: Improve internet check. This just should be a workaround.
			if(!Util.check_database_connection()){
				warning("Gradio cannot connect radio-browser.info. Please check your internet connection.");
				this.quit();
			}

			// Load application settings
			settings = new Settings();

			// Setup application actions
			setup_actions();

			// Setup audio backend
			player = new AudioPlayer();

			image_cache = new ImageCache();

			library = new Library();

			if(settings.enable_mpris == true){
				mpris = new MPRIS();
				mpris.initialize();
			}

			connect_signals();
		}

		private void connect_signals(){
			mpris.requested_quit.connect(this.quit);
			mpris.requested_raise.connect(window.present);

			//search_provider = new SearchProvider.dbus_service ();
			//search_provider.activate.connect ((timestamp) => {
			//	ensure_window ();
			//	window.set_mode(WindowMode.SEARCH);
			//	window.present_with_time (timestamp);
			//});
		}

		protected override void activate () {
			base.activate();
			ensure_window();
			window.present();
		}

		private void setup_actions () {
			// setup actions itself
			var action = new GLib.SimpleAction ("preferences", null);
			action.activate.connect (() => {
			 	SettingsWindow swindow = new SettingsWindow();
			 	swindow.set_transient_for(App.window);
				swindow.set_modal(true);
				swindow.set_visible(true);
			});
			this.add_action (action);

			action = new GLib.SimpleAction ("about", null);
			action.activate.connect (() => { this.show_about_dialog (); });
			this.add_action (action);

			action = new GLib.SimpleAction ("quit", null);
			action.activate.connect (this.quit);
			this.add_action (action);

			action = new GLib.SimpleAction ("select-all", null);
			action.activate.connect (() => { window.select_all(); });
			this.add_action (action);

			action = new GLib.SimpleAction ("select-none", null);
			action.activate.connect (() => { window.select_none (); });
			this.add_action (action);

			// setup appmenu
			var builder = new Gtk.Builder.from_resource ("/de/haecker-felix/gradio/ui/app-menu.ui");
			var app_menu = builder.get_object ("app-menu") as GLib.MenuModel;

			this.register();
			if(GLib.Environment.get_variable("DESKTOP_SESSION") == "gnome") set_app_menu (app_menu);
		}

		private void show_about_dialog(){
			string[] authors = {
				"Felix Häcker <haecker.felix1207@gmail.com>"
			};
			string[] artists = {
				"Juan Pablo Lozano <lozanotux@gmail.com>"
			};
			Gtk.show_about_dialog (window,
				"artists", artists,
				"authors", authors,
				"translator-credits", "translator-credits",
				"program-name", "Gradio",
				"title", "About Gradio",
				"license-type", Gtk.License.GPL_3_0,
				"logo-icon-name", "de.haeckerfelix.gradio",
				"version", Config.VERSION,
				"comments", "Database: www.radio-browser.info",
				"website", "https://github.com/haecker-felix/gradio",
				"wrap-license", true);
		}

		// make sure that window != null, but don't present it
		private void ensure_window(){
			if (get_windows () != null) return;

			window = new MainWindow(this);
			window.delete_event.connect (() => {
				window.hide_on_delete ();

				if(player.state == Gst.State.PLAYING && settings.enable_background_playback)
					return true;
				else
					return false;
		    	});
			window.tray_activate.connect(window.present);
			this.add_window(window);
		}
	}

	int main (string[] args){
		message("Gradio %s ", Config.VERSION);

		// Setup gettext
		Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.GNOMELOCALEDIR);
		Intl.setlocale(LocaleCategory.ALL, "");
		Intl.textdomain(Config.GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "utf-8");

		message("Locale dir: " + Config.GNOMELOCALEDIR);

		// Init gstreamer
		Gst.init (ref args);

		// Init gtk
		Gtk.init(ref args);

		// Init app
		var app = new App ();

		// Run app
		app.run (args);

		return 0;
	}
}
