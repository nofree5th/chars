AS = as -gstabs --32
#AS = as --32
LD = ld -m elf_i386
MKDIR = mkdir -p
RM = rm -f
RMDIR = rmdir
ECHO = echo
ECHO_LD = $(ECHO) '[;32m[  LD  ][0m'
ECHO_AS = $(ECHO) '[;32m[  AS  ][0m'

incs = $(wildcard *-inl.s)
srcs = $(filter-out %-inl.s,$(wildcard *.s))
objs = $(foreach s,$(srcs),.libs/$(basename $(s)).o)

prog = chars

$(shell $(MKDIR) .libs)

.PHONY:all
all:$(objs)
	@$(ECHO_LD) $(prog)
	@$(LD) -o $(prog) $^
	-./$(prog)

.libs/%.o:%.s $(incs)
	@$(ECHO_AS) $<
	@$(AS) -o $@ $<

.PHONY:clean
clean:
	@$(RM) .libs/*.o
	@$(RM) $(prog)
	@$(MKDIR) .libs
	@$(RMDIR) .libs
