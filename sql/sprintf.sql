CREATE OR REPLACE FUNCTION sprintf(text,text,text)
RETURNS TEXT
LANGUAGE plperl
AS $_$
  my ($string, $args, $delim) = @_;
  my $delsplit = defined $delim ? qr{\Q$delim} : qr{\s+};
  return sprintf($string, (split $delsplit, $args));
$_$;
comment on function sprintf(text,text,text) is 'sprintf(fmt,argstring,dlm): format dlm-delimited argstring using fmt';


CREATE OR REPLACE FUNCTION sprintf(text,text)
RETURNS TEXT LANGUAGE sql AS
$_$
  SELECT sprintf($1,$2,null);
$_$;
comment on function sprintf(text,text) is 'sprintf(fmt,argstring): format whitespace-delimited  argstring using fmt';
