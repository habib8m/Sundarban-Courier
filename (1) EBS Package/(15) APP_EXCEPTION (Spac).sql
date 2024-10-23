CREATE OR REPLACE package APPS.app_exception AUTHID CURRENT_USER as
/* $Header: AFEXCEPS.pls 115.4 2002/12/13 02:33:10 tmorrow ship $ */


--
-- Package
--   app_exception
-- Purpose
--   Exception handling utilities
-- History
--   08/09/93	K Brodersen	Created
--

  --
  -- PUBLIC VARIABLES
  --

  -- Exceptions
  application_exception exception;
  record_lock_exception exception;

  -- Exception Pragmas
  pragma exception_init(application_exception, -20001);
  pragma exception_init(record_lock_exception,  -0054);

  --
  -- PUBLIC FUNCTIONS
  --

  --
  -- Name
  --   raise_exception
  -- Purpose
  --   Stores exception information and raises
  --   app_exception.application_exception.
  -- Arguments
  --   exception_type		Exception type
  --   exception_code		Exception code
  --   exception_text		Additional context information
  --
  procedure raise_exception(exception_type varchar2 default null,
                            exception_code number   default null,
                            exception_text varchar2 default null);

  --
  -- Name
  --   get_exception
  -- Purpose
  --   Returns stored exception information.
  -- Arguments
  --   exception_type		Retrieved exception type
  --   exception_code		Retrieved exception code
  --   exception_text		Retrieved context information
  --
  procedure get_exception(exception_type OUT NOCOPY varchar2,
                          exception_code OUT NOCOPY number,
                          exception_text OUT NOCOPY varchar2);
  pragma restrict_references(get_exception, WNDS, WNPS, RNDS);

  --
  -- Name
  --   get_type
  -- Purpose
  --   Returns stored exception type.
  -- Arguments
  --   *None*
  --
  function get_type return varchar2;
  pragma restrict_references(get_type, WNDS, WNPS, RNDS);

  --
  -- Name
  --   get_code
  -- Purpose
  --   Returns stored exception code.
  -- Arguments
  --   *None*
  --
  function get_code return number;
  pragma restrict_references(get_code, WNDS, WNPS, RNDS);

  --
  -- Name
  --   get_text
  -- Purpose
  --   Returns stored exception text.
  -- Arguments
  --   *None*
  --
  function get_text return varchar2;
  pragma restrict_references(get_text, WNDS, WNPS, RNDS);

  --
  -- Name
  --   invalid_argument
  -- Purpose
  --   Display invalid argument error message and raise exception
  -- Arguments
  --   procname		Name  of procedure
  --   argument		Name  of argument
  --   value		Value of argument
  --
  procedure invalid_argument(procname varchar2,
                             argument varchar2,
                             value    varchar2);

end app_exception;
/
