 #########################################################################
#
# Makefile Usage:
# > make
# > make install
# > make remove
# > make pkg
# > make clean
#
# Use the "NO_AUTH=1" option to deploy to roku boxes with firmware < 5.2
#	that do not have the developer username/password
# Important Notes: You must do the following to use this Makefile:
#
# 1) Make sure that you have the make and curl commands line executables
#	 in your path
# 2) Define ROKU_DEV_TARGET either below, or in an environment variable
#	 set to the IP address of your Roku box.
#	 (e.g. export ROKU_DEV_TARGET=192.168.1.1)
#
##########################################################################


# ----------------- YOU CAN EDIT THE VARIABLES BELOW -----------------

# Shell to use when running make commands
SHELL := /bin/bash
# Application version for packaging
VERSION = 0
# Name your app! This will be used for the name of the zip file created
# 	and for packaging the app before publishing to the channel store.
APPNAME = ExitApp

# The username/password you set on your Roku when enabling developer mode
# You are advised to use rokudev / abcd321 to help working together!
ROKU_DEV_USERNAME = rokudev
ROKU_DEV_PASSWORD = developer

# The ip address of the roku box you want to deploy a build to.
# If you use only one box, you can set this in an environment variable
#	but this value will override it

# If your roku box has authentication active (Roku firmwares 5.2 and above),
#	set this to 0
# If you use only one box, you can set this in an environment variable
#	but this value will override it
NO_AUTH=0

APP_KEY_PASS_TMP := /tmp/app_key_pass
DEV_SERVER_TMP_FILE := /tmp/dev_server_out



# --------------------------------------------------------------------------------
# ---------------- STOP EDITING HERE. DON'T CHANGE ANYTHING BELOW!! --------------
# --------------------------------------------------------------------------------

BUILDDIR = build
OUT_DIR = out
PKG_DIR = pkg
TST_DIR = tests
LIBS_DIR = libs


# ZIP and PKG file name
# ifdef BUILD_NUMBER
# 	APP_ZIP_FILE := $(OUT_DIR)/$(APPNAME)_$(PLATFORM)_$(MAJOR_VERSION).$(MINOR_VERSION).$(BUILD_NUMBER).zip
# 	APP_PKG_FILE := $(PKG_DIR)/$(APPNAME)_$(PLATFORM)_$(MAJOR_VERSION).$(MINOR_VERSION).$(BUILD_NUMBER).pkg
# 	APP_TEST_RESULTS_FILE := $(TST_DIR)/$(APPNAME)_$(MAJOR_VERSION).$(MINOR_VERSION).$(BUILD_NUMBER).xml
# else
	APP_ZIP_FILE := $(OUT_DIR)/$(APPNAME).zip
	APP_PKG_FILE := $(PKG_DIR)/$(APPNAME).pkg
	APP_TEST_RESULTS_FILE := $(TST_DIR)/$(APPNAME).xml
# endif

ifdef PLATFORM
	APP_ZIP_FILE_TO_DELETE := $(OUT_DIR)/$(APPNAME)_$(PLATFORM)*.zip
	APP_PKG_FILE_TO_DELETE := $(PKG_DIR)/$(APPNAME)_$(PLATFORM)*.pkg
else
	APP_ZIP_FILE_TO_DELETE := $(OUT_DIR)/$(APPNAME)*.zip
	APP_PKG_FILE_TO_DELETE := $(PKG_DIR)/$(APPNAME)*.pkg
endif

#images source manifest components fonts
APP_INCLUDES = source manifest components images
TEST_LIBRARIES = tests/Main.brs tests/brstest.brs

UNIT_TEST_FOLDER := unit-tests
TEST_RUNNER_SCRIPT := $(UNIT_TEST_FOLDER)/testrunner.sh

# Checks if a specific folder of tests has been set - if empty, run all tests
ifeq ($(TEST_FOLDER), )
	TEST_SUITES = tests/accedo
else
	TEST_SUITES = $(TEST_FOLDER)
endif
ZIP_EXCLUDES = --exclude=*.DS_Store* --exclude=*.git*

$(APPNAME): build zip cleanup
install: $(APPNAME) deploy
test: build addtests zip cleanup deploy runtests

build:
	@echo ""
	@echo ""
	@echo ""
	@echo "1 - I'm removing the previously built"
	@echo "    application archive if it exists and"
	@echo "    setting up all the required directories"
	@echo "    for the final build"
	@echo "--------------------------------------------------------"
	@echo ""

	@if [ -e $(APP_ZIP_FILE_TO_DELETE) ]; \
	then \
		echo "There is an old build here! Deleting it."; \
		rm  $(APP_ZIP_FILE_TO_DELETE); \
		echo "... done." ; \
	fi

	@echo ""

	@if [ ! -d $(OUT_DIR) ]; \
	then \
		echo "Creating missing output directory."; \
		mkdir -p $(OUT_DIR); \
		echo "... done." ; \
	fi

	@if [ ! -w $(OUT_DIR) ]; \
	then \
		echo "Making the output directory writable."; \
		chmod 755 $(OUT_DIR); \
		echo "... done." ; \
	fi

	@if [ -d $(BUILDDIR) ]; \
	then \
		echo "There is an old build directory here! Deleting it."; \
		rm -rf $(BUILDDIR); \
		echo "... done." ; \
	fi

	@if [ ! -d $(BUILDDIR) ]; \
	then \
		echo "Creating a new build directory."; \
		mkdir -p $(BUILDDIR); \
		echo "... done." ; \
	fi

	@if [ ! -w $(BUILDDIR) ]; \
	then \
		echo "Making the build directory writable."; \
		chmod 755 $(BUILDDIR); \
		echo "... done." ; \
	fi
	@echo "... all done!"

	@echo ""
	@echo ""
	@echo ""
	@echo "2 - Before I can fill up this archive, I need"
	@echo "    to have all the source code neatly in one place."
	@echo "    So I'm copying all of that into the build"
	@echo "    dir at $(BUILDDIR)";
	@echo "--------------------------------------------------------"
	@echo ""

	cp -r $(APP_INCLUDES) $(BUILDDIR)/

	@echo "... done."


zip:

	@echo ""
	@echo ""
	@echo ""
	@echo "3 - This is now done, as we're at the final step:"
	@echo "    Zip it all up in $(APP_ZIP_FILE)!"
	@echo "--------------------------------------------------------"
	@echo ""

	pushd ./$(BUILDDIR)/; \
	zip -q -0 -r "../$(APP_ZIP_FILE)" . -i \*.png $(ZIP_EXCLUDES); \
	zip -q -9 -r "../$(APP_ZIP_FILE)" . -x \*.png $(ZIP_EXCLUDES); \
	popd
	@echo "... done."


cleanup:

	@echo ""
	@echo ""
	@echo ""
	@echo "4 - The application archive has been created! Now I'm"
	@echo "    doing a bit of cleanup by build folder '$(BUILDDIR)'"
	@echo "--------------------------------------------------------"
	@echo ""

	rm -rf $(BUILDDIR)
	@echo "... done."


deploy:

	@echo ""
	@echo ""
	@echo ""
	@echo "5 - To install your application, I first need to"
	@echo "    check that you have given me a target to"
	@echo "    deploy to."
	@echo "--------------------------------------------------------"
	@echo ""

	@if [ -z "$(ROKU_DEV_TARGET)" ]; \
	then \
		echo "/!\ It seems you didn't set the ROKU_DEV_TARGET environment variable to the hostname or IP of your device, or set it in the makefile in the editable section."; \
		exit 1; \
	fi
	@echo "... done."

	@echo ""
	@echo ""
	@echo ""
	@echo "6 - Cool, I know where to install your application!"
	@echo "    Now sending it to host $(ROKU_DEV_TARGET)"
	@echo "--------------------------------------------------------"
	@echo ""

	@if [ $(NO_AUTH) = 1 ]; \
	then \
		curl -s -S -F "mysubmit=Install" -F "archive=@$(APP_ZIP_FILE)" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[["; \
	else \
		curl --user $(ROKU_DEV_USERNAME):$(ROKU_DEV_PASSWORD) --digest -s -S -F "mysubmit=Install" -F "archive=@$(APP_ZIP_FILE)" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[["; \
	fi
	@echo "... done."

	@echo ""
	@echo ""
	@echo ""
	@echo "7 - Hey it's all done! Your app '$(APPNAME)' should now"
	@echo "    have oppened on your Roku! Enjoy!"
	@echo "--------------------------------------------------------"
	@echo ""


# -------------------------------------------------------------------------
# pkg: use to create a pkg file from the application sources.
#
# Usage:
# The application name should be specified via $APPNAME.
# The developer's signing password (from genkey) should be passed via
# $APP_KEY_PASS, or via stdin, otherwise the script will prompt for it.
# -------------------------------------------------------------------------
pkg: install
	@echo "Packaging $(APPNAME) on host $(ROKU_DEV_TARGET)"

	@if [ -e $(APP_PKG_FILE_TO_DELETE) ]; \
	then \
		echo "There is an old package here! Deleting it."; \
		rm  $(APP_PKG_FILE_TO_DELETE); \
		echo "... done." ; \
	fi

	@echo "Creating destination directory $(PKG_DIR)"
	@if [ ! -d $(PKG_DIR) ]; \
	then \
		mkdir -p $(PKG_DIR); \
	fi

	@echo "Setting directory permissions for $(PKG_DIR)"
	@if [ ! -w $(PKG_DIR) ]; \
	then \
		chmod 755 $(PKG_DIR); \
	fi

	@echo "Clearing destination directory $(PKG_DIR)"
	rm -f $(PKG_DIR)/*

	@if [ -z "$(ROKU_DEV_TARGET)" ]; \
	then \
		echo "/!\ It seems you didn't set the ROKU_DEV_TARGET environment variable to the hostname or IP of your device, or set it in the makefile in the editable section."; \
		exit 1; \
	fi

	@echo "Packaging $(APPNAME) to $(APP_PKG_FILE)"

	@if [ -z "$(APP_KEY_PASS)" ]; then \
		read -r -p "Password: " REPLY; \
		echo "$$REPLY" > $(APP_KEY_PASS_TMP); \
	else \
		echo "$(APP_KEY_PASS)" > $(APP_KEY_PASS_TMP); \
	fi

	@rm -f $(DEV_SERVER_TMP_FILE)
	@PASSWD=`cat $(APP_KEY_PASS_TMP)`; \
	PKG_TIME=`expr \`date +%s\` \* 1000`; \
	HTTP_STATUS=`curl --user rokudev:$(ROKU_DEV_PASSWORD) --digest --silent --show-error \
		-F "mysubmit=Package" -F "app_name=$(APPNAME)" \
		-F "passwd=$$PASSWD" -F "pkg_time=$$PKG_TIME" \
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_package`; \
	if [ "$$HTTP_STATUS" != "200" ]; then \
		echo "$(COLOR_ERROR)ERROR: Device returned HTTP $$HTTP_STATUS$(COLOR_OFF)"; \
		exit 1; \
	fi

	@MSG=`cat $(DEV_SERVER_TMP_FILE) | grep -o "<font color=\"red\">.*" | sed "s|<font color=\"red\">||" | sed "s|</font>||"`; \
	case "$$MSG" in \
		*Success*) \
			;; \
		*)	@echo "Result: $$MSG"; \
			exit 1 \
			;; \
	esac

	@PKG_LINK=`cat $(DEV_SERVER_TMP_FILE) | grep -o "<a href=\"pkgs//[^\"]*\"" | sed "s|<a href=\"pkgs//||" | sed "s|\"||"`; \
	HTTP_STATUS=`curl --user rokudev:$(ROKU_DEV_PASSWORD) --digest --silent --show-error \
		--output $(APP_PKG_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/pkgs/$$PKG_LINK`; \
	if [ "$$HTTP_STATUS" != "200" ]; then \
		echo "$(COLOR_ERROR)ERROR: Device returned HTTP $$HTTP_STATUS$(COLOR_OFF)"; \
		exit 1; \
	fi

	@echo "*** Package $(APPNAME) complete ***"

# Commenting this one for now.
# If we really want it, we need to build in some error
# 	control when there are no packages available so
# 	curl doesn't explode

# get-pkg:
# 	@echo "RETRIEVING $(APPNAME) on host $(ROKU_DEV_TARGET)"

# 	@if [ ! -d $(PKG_DIR) ]; \
# 	then \
# 		mkdir -p $(PKG_DIR); \
# 	fi

# 	@if [ ! -w $(PKG_DIR) ]; \
# 	then \
# 		chmod 755 $(PKG_DIR); \
# 	fi

# 	@if [ $(NO_AUTH) = 1 ]; \
# 	then \
# 		read -p "Password: " REPLY ; echo $$REPLY | xargs -i curl -s -S -Fmysubmit=Package -Fapp_name=$(APPNAME)/$(VERSION) -Fpasswd={} -Fpkg_time=`expr \`date +%s\` \* 1000` "http://$(ROKU_DEV_TARGET)/plugin_package" | grep 'href="pkgs' | sed 's/.*href=\"\([^\"]*\)\".*/\1/' | sed 's/pkgs\/\///' | xargs -i curl -s -S -o $(PKG_DIR)/$(APPNAME)_{} http://$(ROKU_DEV_TARGET)/pkgs/{}; \
# 	else \
# 		read -p "Password: " REPLY ; echo $$REPLY | xargs -i curl --user $(ROKU_DEV_USERNAME):$(ROKU_DEV_PASSWORD) --digest -s -S -Fmysubmit=Package -Fapp_name=$(APPNAME)/$(VERSION) -Fpasswd={} -Fpkg_time=`expr \`date +%s\` \* 1000` "http://$(ROKU_DEV_TARGET)/plugin_package" | grep 'href="pkgs' | sed 's/.*href=\"\([^\"]*\)\".*/\1/' | sed 's/pkgs\/\///' | xargs -i curl -s -S -o $(PKG_DIR)/$(APPNAME)_{} http://$(ROKU_DEV_TARGET)/pkgs/{}; \
# 	fi

# 	@echo "Done getting $(APPNAME) from host $(ROKU_DEV_TARGET)"

addtests:

	@echo ""
	@echo ""
	@echo ""
	@echo "* - Before I can fill up this archive, I need"
	@echo "    to have all the source code neatly in one place."
	@echo "    So I'm copying all of that into the build"
	@echo "    dir at $(BUILDDIR)";
	@echo "--------------------------------------------------------"
	@echo ""

	cp -r $(TEST_LIBRARIES) $(BUILDDIR)/source  || :
	cp -r $(TEST_SUITES) $(BUILDDIR)/source || :
	@echo "... done. Libs: $(TEST_LIBRARIES), suites: $(TEST_SUITES)"

runtests:

	@if [ ! -f $(TEST_RUNNER_SCRIPT) ]; then \
		echo "$(COLOR_ERROR)ERROR: $(TEST_RUNNER_SCRIPT) does not exist$(COLOR_OFF)"; \
		exit 1; \
	fi

	@if [ -e "$(APP_TEST_RESULTS_FILE)" ]; then \
		echo "  >> removing old application test results file $(APP_TEST_RESULTS_FILE)"; \
		rm $(APP_TEST_RESULTS_FILE); \
	fi

	@if [ ! -d $(TST_DIR) ]; then \
		echo "  >> creating destination directory $(TST_DIR)"; \
		mkdir -p $(TST_DIR); \
	fi

	@if [ ! -w $(TST_DIR) ]; then \
		echo "  >> setting directory permissions for $(TST_DIR)"; \
		chmod 755 $(TST_DIR); \
	fi

	curl -d "" http://$(ROKU_DEV_TARGET):8060/keypress/home
	sleep 1

	$(TEST_RUNNER_SCRIPT) $(ROKU_DEV_TARGET) $(UNIT_TEST_FOLDER) $(APP_TEST_RESULTS_FILE)

remove:

	@if [[ $(NO_AUTH) = 1 ]]; \
	then \
		echo "NOAUTH IS TRUE (remove)"; \
	else \
		echo "NOAUTH IS FALSE (remove)"; \
	fi

	@echo "Removing $(APPNAME) from host $(ROKU_DEV_TARGET)"

	@if [ $(NO_AUTH) = 1 ]; \
	then \
		curl -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[["; \
	else \
		curl --user $(ROKU_DEV_USERNAME):$(ROKU_DEV_PASSWORD) --digest -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[["; \
	fi

clean:
	@echo "Cleaning output directory..."
	@if [ -d $(OUT_DIR) ]; \
	then \
		rm -rf $(OUT_DIR); \
	fi

	@echo "Cleaning build directory..."
	@if [ -d $(BUILDDIR) ]; \
	then \
		rm -rf $(BUILDDIR); \
	fi

	@echo "Cleaning packages directory..."
	@if [ -d $(PKG_DIR) ]; \
	then \
		rm -rf $(PKG_DIR); \
	fi

	@echo "Cleaning tests results directory..."
	@if [ -d $(TST_DIR) ]; \
	then \
		rm -rf $(TST_DIR); \
	fi

	@echo "All done!"
