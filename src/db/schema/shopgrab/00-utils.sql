create or replace function CPAD(text IN VARCHAR, n IN INT, pad IN VARCHAR) return varchar as
begin
    return LPAD(RPAD(text, LENGTH(text) + (n - LENGTH(text)) / 2, pad), n, pad);
end;
/

create or replace function REPEAT(text IN VARCHAR, n IN INT) return varchar as
begin
    return RPAD(text, n, text);
end;
/
