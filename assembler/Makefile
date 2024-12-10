# OFFSET  : Where to load.
#
OFFSET = E000

TARGETS = kimsource-ca65.bin
all: $(TARGETS)

kimsource-ca65.bin kimsource-ca65.map: kimsource-ca65.o kimsource-ca65.cfg
	ld65 -C $(basename $<).cfg -o $@ -vm -m $(basename $<).map $<

kimsource-ca65.cfg: kimsource-ca65.cfg.in Makefile
	sed 's/%%OFFSET%%/$$$(OFFSET)/' $< > $@

clean:
	$(RM) *.o *.lst *.map *.bin *.cfg

distclean: clean
	$(RM) $(TARGETS)

.s.o: 
	ca65 -g -l $(basename $<).lst $<

