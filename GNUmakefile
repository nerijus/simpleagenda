#
# GNUmakefile - Generated by ProjectCenter
#

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.21
PACKAGE_NAME = SimpleAgenda
APP_NAME = SimpleAgenda
SimpleAgenda_APPLICATION_ICON = Calendar.tiff


#
# Libraries
#
SimpleAgenda_LIBRARIES_DEPEND_UPON += -lChronographerSource -lical 

#
# Resource files
#
SimpleAgenda_RESOURCE_FILES = \
Resources/Agenda.gorm \
Resources/Appointment.gorm \
Resources/Preferences.gorm \
Resources/Calendar.tiff 


#
# Header files
#
SimpleAgenda_HEADER_FILES = \
AppController.h \
AgendaStore.h \
LocalStore.h \
AppointmentEditor.h \
CalendarView.h \
StoreManager.h \
DayView.h \
Event.h \
PreferencesController.h \
HourFormatter.h \
UserDefaults.h \
iCalStore.h \
AppointmentCache.h

#
# Class files
#
SimpleAgenda_OBJC_FILES = \
AppController.m \
LocalStore.m \
AppointmentEditor.m \
CalendarView.m \
StoreManager.m \
DayView.m \
Event.m \
PreferencesController.m \
HourFormatter.m \
UserDefaults.m \
iCalStore.m \
AppointmentCache.m

#
# Other sources
#
SimpleAgenda_OBJC_FILES += \
SimpleAgenda.m 

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
