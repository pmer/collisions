---------------------------- MODULE traversal ----------------------------

EXTENDS Integers, TLC, Sequences
CONSTANTS Devices

(*
--algorithm BatchInstall
variables
  AppScope \in [Devices -> {0, 1}];
  Installs \in [Devices -> BOOLEAN];
  batch_pool = {};
  
define
  PoolNotEmpty == batch_pool # {}
end define;
procedure ChangeAppScope()
begin
  Add:  
    AppScope := [d \in Devices |->
        IF d \in batch_pool THEN AppScope[d] + 1
        ELSE AppScope[d] 
     ]; 
  Clean:
    batch_pool := {};
  return;
end procedure;
fair process SyncDevice \in Devices
begin 
  Sync:
    if Installs[self] then
        batch_pool := batch_pool \union {self};
    end if;
end process;
fair process TimeLoop = 0
begin 
  Start:
    while TRUE do
      await PoolNotEmpty;
      call ChangeAppScope();
    end while;
end process;
end algorithm;
*)

\* BEGIN TRANSLATION
VARIABLES AppScope, Installs, batch_pool, pc, stack

(* define statement *)
PoolNotEmpty == batch_pool # {}


vars == << AppScope, Installs, batch_pool, pc, stack >>

ProcSet == (Devices) \cup {0}

Init == (* Global variables *)
        /\ AppScope \in [Devices -> {0, 1}]
        /\ Installs \in [Devices -> BOOLEAN]
        /\ batch_pool = {}
        /\ stack = [self \in ProcSet |-> << >>]
        /\ pc = [self \in ProcSet |-> CASE self \in Devices -> "Sync"
                                        [] self = 0 -> "Start"]

Add(self) == /\ pc[self] = "Add"
             /\ AppScope' =            [d \in Devices |->
                               IF d \in batch_pool THEN AppScope[d] + 1
                               ELSE AppScope[d]
                            ]
             /\ pc' = [pc EXCEPT ![self] = "Clean"]
             /\ UNCHANGED << Installs, batch_pool, stack >>

Clean(self) == /\ pc[self] = "Clean"
               /\ batch_pool' = {}
               /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
               /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]
               /\ UNCHANGED << AppScope, Installs >>

ChangeAppScope(self) == Add(self) \/ Clean(self)

Sync(self) == /\ pc[self] = "Sync"
              /\ IF Installs[self]
                    THEN /\ batch_pool' = (batch_pool \union {self})
                    ELSE /\ TRUE
                         /\ UNCHANGED batch_pool
              /\ pc' = [pc EXCEPT ![self] = "Done"]
              /\ UNCHANGED << AppScope, Installs, stack >>

SyncDevice(self) == Sync(self)

Start == /\ pc[0] = "Start"
         /\ PoolNotEmpty
         /\ stack' = [stack EXCEPT ![0] = << [ procedure |->  "ChangeAppScope",
                                               pc        |->  "Start" ] >>
                                           \o stack[0]]
         /\ pc' = [pc EXCEPT ![0] = "Add"]
         /\ UNCHANGED << AppScope, Installs, batch_pool >>

TimeLoop == Start

Next == TimeLoop
           \/ (\E self \in ProcSet: ChangeAppScope(self))
           \/ (\E self \in Devices: SyncDevice(self))

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Devices : WF_vars(SyncDevice(self))
        /\ WF_vars(TimeLoop) /\ WF_vars(ChangeAppScope(0))

\* END TRANSLATION

=============================================================================
