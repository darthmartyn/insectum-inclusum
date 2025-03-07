with GNAT.IO; use GNAT.IO;

procedure MyProcess is
   type Modular_Byte is mod 256;
   Incrementing_Variable : Modular_Byte := Modular_Byte'First;
   Has_Been_Debugged : Boolean := False with Volatile;
begin

   Put_Line ("Waiting to be interrupted...");

   loop
      -- A debugger is to breakpoint on the next line and set Has_Been_Debugged to True
      Incrementing_Variable := Modular_Byte'Succ (Incrementing_Variable); -- <<< breakpoint here
      exit when Has_Been_Debugged;
   end loop;

   -- If the debugger connected and manipulated Has_Been_Debugged correctly, the
   -- next line should be executed.
   Put_Line ("Debugger did its job!");

end MyProcess;

