listener = openListener "$:8088"
verbose = true

hexdigits := "0123456789ABCDEF"
hext := new HashTable from for i from 0 to 15 list hexdigits#i => i
hex1 := c -> if hext#?c then hext#c else 0
hex2 = (c,d) -> 16 * hex1 c + hex1 d
toHex1 := asc -> ("%",hexdigits#(asc>>4),hexdigits#(asc&15))
toHex := str -> concatenate apply(ascii str, toHex1)

server = () -> (
    stderr << "listening:" << endl;
    while true do (
        local fun; local s;
        wait {listener};
        g := openInOut listener;				    -- this should be interruptable!
        r := read g;
--	<< "r0 " << r << endl;	
        if verbose then stderr << "request: " << stack lines r << endl;
	<< "------------------------" << endl;
--	<< "r1 " << r << endl;
        r = lines r;
--	<< "r2 " << r << endl;	
        if #r == 0 then (close g; continue);
	data := last r;
--	<< "r3 " << r << endl;	
--	<< "data=" << data << endl;
        r = first r;
        if match("^GET /fcn1/",r) then (
            s = first select("^GET /fcn1/(.*) ", "\\1", r);
            fun = fcn1;
            )
	  else if match("^GET /fcn2/(.*) ",r) then (
	       s = first select("^GET /fcn2/(.*) ", "\\1", r);
	       fun = fcn2;
	       )
	  else if match("^GET /end/(.*) ",r) then (
    	       return;
	       )
	  else if match("^POST /eval/(.*) ",r) then (
	       s = data; -- first select("^POST /eval/(.*) ", "\\1", r);
	       fun = ev;
	       )
	  else if match("^HEAD /(.*) ",r) then (
	       s = first select("^HEAD /(.*) ", "\\1", r);
	       fun = identity;
	       )
	  else (
	       s = "";
	       fun = identity;
	       );
--	<< "s " << s << endl;	
	  t := select(".|%[0-9A-F]{2,2}", data); --s);
--	<< "t " << t << endl;		  
	  u := apply(t, x -> if #x == 1 then x else ascii hex2(x#1, x#2));
	  u = concatenate u;
	  << "this is a test of functioning" << endl;
	  << u << endl;
	  << fun u << endl;
	<< "------------------------" << endl;	  
  	  << httpHeaders fun u << endl;
      g << httpHeaders fun u << close;
	  )
     )

ev = x -> "called POST ev on " | x
fcn1 = x -> "called fcn1 on " | x
fcn2 = x -> "called fcn2 on " | x
--test = fun u

end

restart
load"server.m2"
server()
close listener
