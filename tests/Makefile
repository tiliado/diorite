#!/usr/bin/make -f

NAME = testcase
PACKAGES = glib-2.0 gtk+-3.0
BUILD = ../build
OUT    = $(BUILD)/tests
RUN = $(OUT)/run
VALAC        ?= valac
VALAFLAGS   ?=  
CC ?= gcc
CFLAGS ?= -g -O2
LDFLAGS ?= 
TESTGEN ?= ../testgen.py 
VALA_FILES = $(wildcard *.vala)
C_FILES=$(patsubst %.vala,$(OUT)/%.c, $(VALA_FILES))
O_FILES = $(C_FILES:c=o)
H_FILE = $(OUT)/$(NAME).h
VAPI_FILE = $(OUT)/$(NAME).vapi
CFLAGS += -I$(OUT) -I$(BUILD)
CFLAGS += $(shell pkg-config --cflags $(PACKAGES))
LDFLAGS += -L$(OUT) -L$(BUILD) -ldioriteglib-0.1 -ldioritegtk-0.1 -ldioritedb-0.1
LDFLAGS += $(shell pkg-config --libs $(PACKAGES))
VALAFLAGS += --vapidir $(OUT) --vapidir $(BUILD) --vapidir ../vapi
VALAFLAGS += $(PACKAGES:%=--pkg=%)
VALAFLAGS += --pkg dioriteglib-0.1 --pkg dioritegtk-0.1 --pkg dioritedb-0.1
LIBPREFIX = lib
LIBSUFFIX = .so
LIBRARYSO=$(LIBPREFIX)$(NAME)$(LIBSUFFIX)

run: all
	LD_LIBRARY_PATH=".:$(OUT):$(BUILD)" $(RUN)/$(NAME)

all: $(RUN)/$(NAME)


$(RUN):
	mkdir -p $(RUN)

$(RUN)/$(NAME): $(RUN)/$(NAME).o
	$(CC) $< -o $@ $(LDFLAGS) -l$(NAME) 

$(RUN)/$(NAME).o: $(RUN)/$(NAME).c
	$(CC) $^ -c -o $@ -fPIC '-DG_LOG_DOMAIN="DioriteTest"' $(CFLAGS)
	
$(RUN)/$(NAME).c: $(RUN)/$(NAME).vala $(OUT)/$(LIBRARYSO)
	$(VALAC) -C -d $(OUT) -b $(OUT) --thread -v \
	--target-glib=2.32 --pkg $(NAME) $(VALAFLAGS) $<

$(RUN)/$(NAME).vala: $(VALA_FILES) | $(RUN)
	$(TESTGEN) -o $@ $(VALA_FILES)

$(OUT)/$(LIBRARYSO): $(O_FILES)
	$(CC) $^ -o $@ -shared $(LDFLAGS)

%.o : %.c
	$(CC) $^ -c -o $@ -fPIC '-DG_LOG_DOMAIN="DioriteTest"' $(CFLAGS)

$(C_FILES) : $(VALA_FILES)
	$(VALAC) -C -d $(OUT) -b . --thread -v \
	--library=$(NAME) -H $(H_FILE)  \
	--target-glib=2.32 $(VALAFLAGS) $(VALA_FILES)

clean:
	rm -rf $(C_FILES) $(H_FILE)  $(VAPI_FILE) $(O_FILES) $(LIBRARYSO) $(RUN)
