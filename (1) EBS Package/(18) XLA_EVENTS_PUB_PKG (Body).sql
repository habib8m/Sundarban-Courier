CREATE OR REPLACE PACKAGE BODY APPS.xla_events_pub_pkg AS
-- $Header: xlaevevp.pkb 120.37.12020000.2 2014/01/10 11:45:04 tasrivas ship $
/*===========================================================================+
|             Copyright (c) 2001-2014 Oracle Corporation                     |
|                       Redwood Shores, CA, USA                              |
|                         All rights reserved.                               |
+============================================================================+
| FILENAME                                                                   |
|    xlaevevp.pkb                                                            |
|                                                                            |
| PACKAGE NAME                                                               |
|    xla_events_pub_pkg                                                      |
|                                                                            |
| DESCRIPTION                                                                |
|    This is a public package for product teams, which contains all the      |
|    APIs required for processing accounting events.                         |
|                                                                            |
|    Note: the APIs do not excute COMMIT or ROLLBACK.                        |
|                                                                            |
|    These public APIs are wrapper over public routines of xla_event_pkg     |
|                                                                            |
| HISTORY                                                                    |
|    08-Feb-01 G. Gu           Created                                       |
|    10-Mar-01 P. Labrevois    Reviewed                                      |
|    17-Jul-01 P. Labrevois    Added array create_event                      |
|    13-Sep-01 P. Labrevois    Added 2nd array create_event                  |
|    08-Feb-02 S. Singhania    Reviewed and performed major changes          |
|    10-Feb-02 S. Singhania    Made changes in APIs to handle 'Transaction   |
|                               Number' (new column added in xla_entities)   |
|    13-Feb-02 S. Singhania    Made changes in APIs to handle 'Event Number' |
|    17-Feb-02 S. Singhania    Added 'Org_id' parameter to all the APIs as a |
|                               'security context'                           |
|    04-Apr-02 S. Singhania    Replaced 'Org_id' parameter with the generic  |
|                                paramenter 'p_security_context'. Removed the|
|                                not required, redundant APIs                |
|    17-Apr-02 S. Singhania    Removed shadow procedures. Added seperate APIs|
|                                to update transaction number, Event Number  |
|                                and Reference Information                   |
|    06-May-02 S. Singhania    Added "valuation_method" and "ledger_id".     |
|                                Bug # 2351677.                              |
|    31-May-02 S. Singhania    Removed one of the 'create_entity_event' API  |
|                              Renamed 'create_entity_event' API to          |
|                                'create_bulk_events'                        |
|    23-Jul-02 S. Singhania    commented 'get_document_status' API.          |
|                                Bug # 2464825                               |
|    09-Sep-02 S. Singhania    modified 'create_bulk_events' API. Bug 2530796|
|    21-Feb-03 S. Singhania    Added 'Trace' procedure.                      |
|    04-Sep-03 S. Singhania    Made changes to satisfy enhanced requirement  |
|                                for 'Source Application'.                   |
|                                - Added parameter to CREATE_BULK_EVENTS     |
|    12-Dec-03 S. Singhania    Removed the API UPDATE_TRANSACTION_NUMBER.    |
|                                Bug # 3268790                               |
|    25-Jun-04 W. Shen         add a new function delete_entity(bug 3316535) |
|    23-OCT-04 W. Shen         New API to delete/update/create event in bulk |
|    1- APR-05 W. Shen         Add transaction_date to create_event api      |
|                                add transaction_date to update_event API    |
|    20-Apr-05 S. Singhania    Bug 4312353. Modified the calls to routines in|
|                                xla_events_pkg to reflect the change in the |
|                                way we handle valuation method different    |
|                                from other security columns                 |
|    02-May-05 V. Kumar        Removed function create_bulk_events,          |
|                              Bug # 4323140                                 |
|    30-SEP-10 VDAMERLA        Bug:9077926  Created overloaded procedures    |
|                                for create_bulk_events and                  |
|                                update_bulk_event_statuses to pass          |
|                                bulk limit value                            |
|    13-Oct-10 nksurana        Bug 10152910 Created new function/API         |
|                              allow_third_party_update to check if the party|
|                              site can be updated, based on Control Account.|
+===========================================================================*/

--=============================================================================
--               *********** Local Trace Routine **********
--=============================================================================
C_LEVEL_STATEMENT     CONSTANT NUMBER := FND_LOG.LEVEL_STATEMENT;
C_LEVEL_PROCEDURE     CONSTANT NUMBER := FND_LOG.LEVEL_PROCEDURE;
C_LEVEL_EVENT         CONSTANT NUMBER := FND_LOG.LEVEL_EVENT;
C_LEVEL_EXCEPTION     CONSTANT NUMBER := FND_LOG.LEVEL_EXCEPTION;
C_LEVEL_ERROR         CONSTANT NUMBER := FND_LOG.LEVEL_ERROR;
C_LEVEL_UNEXPECTED    CONSTANT NUMBER := FND_LOG.LEVEL_UNEXPECTED;

C_LEVEL_LOG_DISABLED  CONSTANT NUMBER := 99;

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'xla.plsql.xla_events_pub_pkg';

g_debug_flag      VARCHAR2(1) := NVL(fnd_profile.value('XLA_DEBUG_TRACE'),'N');

--l_log_module          VARCHAR2(240);
g_log_level           NUMBER;
g_log_enabled         BOOLEAN;



PROCEDURE trace
       (p_msg                        IN VARCHAR2
       ,p_level                      IN NUMBER
       ,p_module                     IN VARCHAR2 DEFAULT C_DEFAULT_MODULE) IS
BEGIN
   IF (p_msg IS NULL AND p_level >= g_log_level) THEN
      fnd_log.message(p_level, p_module);
   ELSIF p_level >= g_log_level THEN
      fnd_log.string(p_level, p_module, p_msg);
   END IF;
EXCEPTION
   WHEN xla_exceptions_pkg.application_exception THEN
      RAISE;
   WHEN OTHERS THEN
      xla_exceptions_pkg.raise_message
         (p_location   => 'xla_acct_setup_pub_pkg.trace');
END trace;


--=============================================================================
--          *********** Event creation routines **********
--=============================================================================
--=============================================================================
--
--
--
--
--
--
--
--
--
--
-- 1.    create_event
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--=============================================================================

--============================================================================
--
-- This procedure is used to create an event and returns event id.
-- It will also
--    - validate input parameters(except reference columns)
--    - create a new event
--
--============================================================================

FUNCTION create_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_type_code              IN  VARCHAR2
   ,p_event_date                   IN  DATE
   ,p_event_status_code            IN  VARCHAR2
   ,p_event_number                 IN  INTEGER        DEFAULT NULL
   ,p_transaction_date             IN  DATE        DEFAULT NULL
   ,p_reference_info               IN  xla_events_pub_pkg.t_event_reference_info DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN INTEGER IS
BEGIN
   trace('@ xla_events_pub_pkg.create_event (fn)'             , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   RETURN xla_events_pkg.create_event
            (p_event_source_info        => p_event_source_info
            ,p_valuation_method         => p_valuation_method
            ,p_event_type_code          => p_event_type_code
            ,p_event_date               => p_event_date
            ,p_event_status_code        => p_event_status_code
            ,p_event_number             => p_event_number
            ,p_transaction_date         => p_transaction_date
            ,p_reference_info           => p_reference_info
            ,p_budgetary_control_flag   => 'N');
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.create_event (fn)');
END create_event;

--============================================================================
--
-- This procedure is used to create an event and returns event id.
-- It will also
--    - validate input parameters(except reference columns)
--    - create a new event
--
--============================================================================
FUNCTION create_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_type_code              IN  VARCHAR2
   ,p_event_date                   IN  DATE
   ,p_event_status_code            IN  VARCHAR2
   ,p_event_number                 IN  INTEGER        DEFAULT NULL
   ,p_transaction_date             IN  DATE        DEFAULT NULL
   ,p_reference_info               IN  xla_events_pub_pkg.t_event_reference_info DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_budgetary_control_flag       IN  VARCHAR2)
RETURN INTEGER IS
BEGIN
   trace('@ xla_events_pub_pkg.create_event (fn)'             , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;

   RETURN xla_events_pkg.create_event
            (p_event_source_info        => p_event_source_info
            ,p_valuation_method         => p_valuation_method
            ,p_event_type_code          => p_event_type_code
            ,p_event_date               => p_event_date
            ,p_event_status_code        => p_event_status_code
            ,p_event_number             => p_event_number
            ,p_transaction_date         => p_transaction_date
            ,p_reference_info           => p_reference_info
            ,p_budgetary_control_flag   => p_budgetary_control_flag);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.create_event (fn)');
END create_event;


-------------------------------------------------------------------------------
-- Event updation routines
-------------------------------------------------------------------------------

--============================================================================
--
-- This procedure is used to manipulate the status of an event. It will
--    - validate input parameters
--    - lock the document
--    - ensure all selected events status are not 'Processed'
--    - update event
--
--============================================================================

PROCEDURE update_event_status
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security) IS
BEGIN
   trace('> xla_events_pub_pkg.update_event_status'           , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   xla_events_pkg.update_event_status
      (p_event_source_info       => p_event_source_info
      ,p_valuation_method        => p_valuation_method
      ,p_event_class_code        => p_event_class_code
      ,p_event_type_code         => p_event_type_code
      ,p_event_date              => p_event_date
      ,p_event_status_code       => p_event_status_code);

   trace('< xla_events_pub_pkg.update_event_status'           , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_event_status');
END update_event_status;


--============================================================================
--
-- This procedure is used to manipulate the type, status, and/or date for a
-- specific event.
--    - validate input parameters
--    - lock the document
--    - ensure all selected events status are not 'Processed'
--    - update event
--
--============================================================================

PROCEDURE update_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_transaction_date             IN  DATE       DEFAULT NULL) IS
BEGIN
   trace('> xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   xla_events_pkg.update_event
      (p_event_source_info        => p_event_source_info
      ,p_valuation_method         => p_valuation_method
      ,p_event_id                 => p_event_id
      ,p_event_type_code          => p_event_type_code
      ,p_event_date               => p_event_date
      ,p_event_status_code        => p_event_status_code
      ,p_transaction_date         => p_transaction_date);

   trace('< xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_event');
END update_event;


--============================================================================
--
-- This procedure is used to manipulate the type, status, date and/or
-- event numberany for a specific event.
--    - validate input parameters
--    - lock the document
--    - ensure all selected events status are not 'Processed'
--    - update event
--
--============================================================================

PROCEDURE update_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_event_number                 IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_transaction_date             IN  DATE       DEFAULT NULL) IS
BEGIN
   trace('> xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   xla_events_pkg.update_event
      (p_event_source_info        => p_event_source_info
      ,p_valuation_method         => p_valuation_method
      ,p_event_id                 => p_event_id
      ,p_event_type_code          => p_event_type_code
      ,p_event_date               => p_event_date
      ,p_event_status_code        => p_event_status_code
      ,p_transaction_date         => p_transaction_date
      ,p_event_number             => p_event_number
      ,p_overwrite_event_num      => 'Y');

   trace('< xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_event');
END update_event;


--============================================================================
--
-- This procedure is used to manipulate the type, status, date or any
-- reference information for a specific event.
--    - validate input parameters
--    - lock the document
--    - ensure all selected events status are not 'Processed'
--    - update event
--
--============================================================================

PROCEDURE update_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_reference_info               IN  xla_events_pub_pkg.t_event_reference_info
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_transaction_date             IN  DATE       DEFAULT NULL) IS
BEGIN
   trace('> xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   xla_events_pkg.update_event
      (p_event_source_info        => p_event_source_info
      ,p_valuation_method         => p_valuation_method
      ,p_event_id                 => p_event_id
      ,p_event_type_code          => p_event_type_code
      ,p_event_date               => p_event_date
      ,p_event_status_code        => p_event_status_code
      ,p_transaction_date         => p_transaction_date
      ,p_reference_info           => p_reference_info
      ,p_overwrite_ref_info       => 'Y' );

   trace('< xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_event');
END update_event;


--============================================================================
--
-- This procedure is used to manipulate the type, status, date, event number
-- and/or any reference information for a specific event.
--    - validate input parameters
--    - lock the document
--    - ensure all selected events status are not 'Processed'
--    - update event
--
--============================================================================

PROCEDURE update_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_event_number                 IN  INTEGER
   ,p_reference_info               IN  xla_events_pub_pkg.t_event_reference_info
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_transaction_date             IN  DATE       DEFAULT NULL) IS
BEGIN
   trace('> xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   xla_events_pkg.update_event
      (p_event_source_info        => p_event_source_info
      ,p_valuation_method         => p_valuation_method
      ,p_event_id                 => p_event_id
      ,p_event_type_code          => p_event_type_code
      ,p_event_date               => p_event_date
      ,p_event_status_code        => p_event_status_code
      ,p_transaction_date         => p_transaction_date
      ,p_event_number             => p_event_number
      ,p_reference_info           => p_reference_info
      ,p_overwrite_event_num      => 'Y'
      ,p_overwrite_ref_info       => 'Y');

   trace('< xla_events_pub_pkg.update_event'                  , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_event');
END update_event;


-------------------------------------------------------------------------------
-- Event deletion routines
-------------------------------------------------------------------------------

--============================================================================
--
-- This procedure is used to delete one event. It will:
--    - validate input parameters
--    - lock the document
--    - ensure all selected events status are not 'Processed'
--    - delete event
--
--============================================================================

PROCEDURE delete_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security) IS
BEGIN
   trace('> xla_events_pub_pkg.delete_event'                  , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
   --xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   xla_events_pkg.delete_event
      (p_event_source_info     => p_event_source_info
      ,p_valuation_method         => p_valuation_method
      ,p_event_id              => p_event_id );

   trace('< xla_events_pub_pkg.delete_event'                  , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.delete_event');
END delete_event;


--============================================================================
--
-- This procedure is used to delete one to many event for a document and
-- return the number or record deleted. It will:
--    - validate input parameters
--    - lock the document
--    - ensure all selected events status are not 'Processed'
--    - delete unprocessed event(s)
--
--============================================================================

FUNCTION delete_events
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN INTEGER IS
BEGIN
   trace('@ xla_events_pub_pkg.delete_events (fn)'             , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   RETURN xla_events_pkg.delete_events
            (p_event_source_info      => p_event_source_info
            ,p_event_class_code       => p_event_class_code
            ,p_valuation_method         => p_valuation_method
            ,p_event_type_code        => p_event_type_code
            ,p_event_date             => p_event_date);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.delete_events(fn)');
END delete_events;


--============================================================================
--
-- This function is used to delete one entity. It will:
--    - validate input parameters
--    - check if there is still event associated with the entity
--    - if yes, return 1 without deletion
--    - else delete entity, return 0
--
--============================================================================
FUNCTION delete_entity
   (p_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN INTEGER IS
l_result INTEGER;
BEGIN
   trace('> xla_events_pub_pkg.delete_entty'                  , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   l_result := xla_events_pkg.delete_entity
      (p_source_info         => p_source_info
      ,p_valuation_method    => p_valuation_method);

   trace('< xla_events_pub_pkg.delete_entity'                  , C_LEVEL_PROCEDURE);
   return l_result;
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.delete_entity');
END delete_entity;

-------------------------------------------------------------------------------
-- Event information routines
-------------------------------------------------------------------------------

--============================================================================
--
-- This procedure is used to get information for a specific event. It
-- will:
--    - lock the document
--    - get the information
--
--============================================================================

FUNCTION get_event_info
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN xla_events_pub_pkg.t_event_info IS
BEGIN
   trace('@ xla_events_pub_pkg.get_event_info'                , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   RETURN xla_events_pkg.get_event_info
            (p_event_source_info        => p_event_source_info
            ,p_valuation_method         => p_valuation_method
            ,p_event_id                 => p_event_id);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.get_event_info');
END get_event_info;


--============================================================================
--
-- This procedure is used to get status for a specific event. It will:
--    - lock the document
--    - get the information
--
--============================================================================

FUNCTION get_event_status
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN VARCHAR2 IS
BEGIN
   trace('@ xla_events_pub_pkg.get_event_status'         , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   RETURN xla_events_pkg.get_event_status
            (p_event_source_info        => p_event_source_info
            ,p_valuation_method         => p_valuation_method
            ,p_event_id                 => p_event_id);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.get_event_status');
END get_event_status;


--============================================================================
--
-- This procedure is used to detect the existency of a particular event.
--
--============================================================================

FUNCTION event_exists
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_event_number                 IN  INTEGER    DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN BOOLEAN IS
BEGIN
   trace('@ xla_events_pub_pkg.event_exists'                  , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   RETURN xla_events_pkg.event_exists
            (p_event_source_info       => p_event_source_info
            ,p_valuation_method        => p_valuation_method
            ,p_event_class_code        => p_event_class_code
            ,p_event_type_code         => p_event_type_code
            ,p_event_date              => p_event_date
            ,p_event_status_code       => p_event_status_code
            ,p_event_number            => p_event_number);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.event_exists');
END event_exists;


--============================================================================
--
-- This procedure is used to get information for all events associated
-- to a document. It will
--    - lock the document
--    - get the information
--    - return the information
--
--============================================================================

FUNCTION get_array_event_info
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN xla_events_pub_pkg.t_array_event_info IS
BEGIN
   trace('@ xla_events_pub_pkg.get_array_event_info'          , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
--   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   RETURN xla_events_pkg.get_array_event_info
            (p_event_source_info       => p_event_source_info
            ,p_valuation_method        => p_valuation_method
            ,p_event_class_code        => p_event_class_code
            ,p_event_type_code         => p_event_type_code
            ,p_event_date              => p_event_date
            ,p_event_status_code       => p_event_status_code);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.get_array_event_info');
END get_array_event_info;

PROCEDURE create_bulk_events
       (p_source_application_id        IN  INTEGER     DEFAULT NULL
       ,p_application_id               IN  INTEGER
       ,p_legal_entity_id              IN  INTEGER     DEFAULT NULL
       ,p_ledger_id                    IN  INTEGER
       ,p_entity_type_code             IN  VARCHAR2) IS
BEGIN
  trace('>BEGIN of procedure xla_events_pub_pkg.create_bulk_events'                  , C_LEVEL_PROCEDURE);
  xla_events_pkg.create_bulk_events(
       p_source_application_id    => p_source_application_id
       , p_application_id           => p_application_id
       , p_legal_entity_id          => p_legal_entity_id
       , p_ledger_id                => p_ledger_id
       , p_entity_type_code         => p_entity_type_code);
  trace('>END of procedure xla_events_pub_pkg.create_bulk_events'                  , C_LEVEL_PROCEDURE);

EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.create_bulk_events');
END create_bulk_events;


PROCEDURE create_bulk_events
       (p_source_application_id        IN  INTEGER     DEFAULT NULL
       ,p_application_id               IN  INTEGER
       ,p_legal_entity_id              IN  INTEGER     DEFAULT NULL
       ,p_ledger_id                    IN  INTEGER
       ,p_entity_type_code             IN  VARCHAR2
       ,p_limit_size                   IN  INTEGER) IS
BEGIN
  trace('>BEGIN of procedure xla_events_pub_pkg.create_bulk_events'                  , C_LEVEL_PROCEDURE);
  xla_events_pkg.create_bulk_events(
       p_source_application_id    => p_source_application_id
       , p_application_id           => p_application_id
       , p_legal_entity_id          => p_legal_entity_id
       , p_ledger_id                => p_ledger_id
       , p_entity_type_code         => p_entity_type_code
       , p_limit_size               => p_limit_size);
  trace('>END of procedure xla_events_pub_pkg.create_bulk_events'                  , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.create_bulk_events');
END create_bulk_events;

PROCEDURE update_bulk_event_statuses(p_application_id INTEGER) IS
BEGIN
  trace('>BEGIN of procedure xla_events_pub_pkg.update_bulk_event_statuses'                  , C_LEVEL_PROCEDURE);
  xla_events_pkg.update_bulk_event_statuses(
       p_application_id           => p_application_id);
  trace('>END of procedure xla_events_pub_pkg.update_bulk_event_statuses'                  , C_LEVEL_PROCEDURE);

EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_bulk_event_statuses');
END update_bulk_event_statuses;


PROCEDURE update_bulk_event_statuses(p_application_id                IN  INTEGER
                                     ,p_limit_size                   IN  INTEGER)  IS
BEGIN
  trace('>BEGIN of procedure xla_events_pub_pkg.update_bulk_event_statuses'                  , C_LEVEL_PROCEDURE);
  xla_events_pkg.update_bulk_event_statuses(
       p_application_id           => p_application_id
       ,p_limit_size               => p_limit_size);
  trace('>END of procedure xla_events_pub_pkg.update_bulk_event_statuses'                  , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_bulk_event_statuses');
END update_bulk_event_statuses;



PROCEDURE delete_bulk_events(p_application_id INTEGER) IS
BEGIN
  xla_events_pkg.delete_bulk_events(
       p_application_id           => p_application_id);

EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS  THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.delete_bulk_events');
END delete_bulk_events;

-- For subledger teams uptake of Period Close validation.
PROCEDURE period_close  (p_api_version    IN NUMBER
                        ,x_return_status  IN OUT NOCOPY VARCHAR2
                        ,p_application_id IN NUMBER
                        ,p_ledger_id      IN NUMBER
                        ,p_period_name    IN VARCHAR2) IS

l_log_module       VARCHAR2(240);
l_return_status    VARCHAR2(16);
l_api_name         CONSTANT VARCHAR2(30) := 'period_close';
l_api_version      CONSTANT NUMBER       := 1.0;
l_adjustment_flag  VARCHAR2(10);
BEGIN

   IF g_log_enabled THEN
     l_log_module := C_DEFAULT_MODULE||'.period_close';
   END IF;

   IF (C_LEVEL_PROCEDURE >= g_log_level) THEN
        trace
           ( p_msg      => 'BEGIN of Period Close Function for Subledger check'
            ,p_level    => C_LEVEL_PROCEDURE
            ,p_module   => l_log_module);
   END IF;

   IF (NOT fnd_api.compatible_api_call
                 (p_current_version_number => p_api_version
                 ,p_caller_version_number  => l_api_version
                 ,p_api_name               => l_api_name
                 ,p_pkg_name               => C_DEFAULT_MODULE)) THEN
      RAISE  FND_API.G_EXC_UNEXPECTED_ERROR;
   ELSE

      /******************************/
     /*** Added for bug 9286886 ****/
     /******************************/

     BEGIN

      SELECT adjustment_period_flag
      INTO   l_adjustment_flag
      FROM   gl_period_statuses
      WHERE  application_id = p_application_id
      AND    ledger_id      = p_ledger_id
      AND    period_name    = p_period_name;

     EXCEPTION
     --BUG 12312395
     -- Changed from WHEN NO DATA FOUND to OTHERS
      WHEN OTHERS THEN
        RAISE;
     END;

      /*** Added for bug 9286886 ***/

      IF NVL(l_adjustment_flag, 'N') <> 'Y'
      THEN
         l_return_status :=  xla_events_pkg.period_close
                           (p_application_id    => p_application_id
                           ,p_ledger_id         => p_ledger_id
                           ,p_period_name       => p_period_name);

         IF l_return_status = 'TRUE' THEN
            x_return_status := FND_API.G_RET_STS_SUCCESS;
         ELSIF l_return_status = 'FALSE' THEN
            x_return_status := FND_API.G_RET_STS_ERROR;
         ELSIF l_return_status = 'ERROR' THEN
           x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         END IF;

      ELSE                /*   Else if of l_adjustment_flag */
         x_return_status := FND_API.G_RET_STS_SUCCESS;

      END IF;             /* End if of l_adjustment_flag */


   END IF;

   IF (C_LEVEL_PROCEDURE >= g_log_level) THEN
       trace
           ( p_msg      => 'End of Period Close Function for Subledger check'
            ,p_level    => C_LEVEL_PROCEDURE
            ,p_module   => l_log_module);
   END IF;

EXCEPTION
  WHEN  FND_API.G_EXC_UNEXPECTED_ERROR THEN
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
  WHEN OTHERS THEN
     IF (C_LEVEL_PROCEDURE >= g_log_level) THEN
         trace
           ( p_msg      => 'End of Period Close function for Subledger
	                    check with error'
            ,p_level    => C_LEVEL_PROCEDURE
            ,p_module   => l_log_module);
     END IF;
     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
END period_close;

FUNCTION period_close(p_subscription_guid   IN raw
                     ,p_event               IN OUT NOCOPY WF_EVENT_T)
RETURN VARCHAR2 is

l_parameter_list        WF_PARAMETER_LIST_T;
l_ledger_id             NUMBER;
l_period_name           VARCHAR2(100);
l_log_module            VARCHAR2(240);
return_status           VARCHAR2(10);
l_adjustment_flag       VARCHAR2(10); -- Bug 12312395
BEGIN

  -- get the parameter of the event
  l_parameter_list := p_event.getParameterList;
  l_period_name := wf_event.getValueForParameter('PERIOD_NAME',
						 l_parameter_list);
  l_ledger_id := to_number(wf_event.getValueForParameter('LEDGER_ID',
	                   l_parameter_list));

    /******************************/
     /*** Added for bug 12312395 ****/
     /******************************/

     BEGIN

      SELECT adjustment_period_flag
      INTO   l_adjustment_flag
      FROM   gl_period_statuses
      WHERE  application_id = 101
      AND    ledger_id      = l_ledger_id
      AND    period_name    = l_period_name;

     EXCEPTION
      WHEN OTHERS THEN
        RAISE;
     END;

      /*** Added for bug 12312395 ***/

      IF NVL(l_adjustment_flag, 'N') <> 'Y'
      THEN

  	return_status :=  xla_events_pkg.period_close
               (p_period_name    => l_period_name
               ,p_ledger_id      => l_ledger_id
               ,p_mode           => 'W');
      ELSE                /*   Else if of l_adjustment_flag(bug 12312395) */
         return_status := 'SUCCESS';

      END IF;             /* End if of l_adjustment_flag(bug 12312395) */


  RETURN return_status;

EXCEPTION

WHEN xla_exceptions_pkg.application_exception THEN

  WF_CORE.CONTEXT( 'xla_events_pub_pkg', 'period_close',
                    p_event.getEventName( ), p_subscription_guid);
  WF_EVENT.setErrorInfo(p_event, 'ERROR');
  RETURN 'ERROR';
 -- Added for Bug 12312395
 WHEN OTHERS THEN
  RETURN 'ERROR';

END period_close;

--added bug6737299 update transaction number procedure

-------------------------------------------------------------------------------
-- Entity update routines
-------------------------------------------------------------------------------

--============================================================================
--
-- This procedure updates transaction number on the document.
--
--============================================================================

PROCEDURE update_transaction_number
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_transaction_number           IN  VARCHAR2
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_event_id                     IN  NUMBER  DEFAULT NULL) IS -- 8761772
BEGIN
   trace('> xla_events_pub_pkg.update_transaction_number'             , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   xla_events_pkg.update_transaction_number
      (p_event_source_info     => p_event_source_info
      ,p_transaction_number    => p_transaction_number
      ,p_valuation_method      => p_valuation_method
      ,p_event_id              => p_event_id
      );

   trace('< xla_events_pub_pkg.update_transaction_number'             , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.update_transaction_number');
END update_transaction_number;


-------------------------------------------------------------------------------
-- Control Account Information routines
-------------------------------------------------------------------------------

--============================================================================
--
-- This function returns TRUE if the party site for the transaction can be updated
-- based on whether it has any accounted information for a Control Account.
--============================================================================

FUNCTION allow_third_party_update
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN BOOLEAN IS
BEGIN
   trace('> xla_events_pub_pkg.allow_third_party_update'             , C_LEVEL_PROCEDURE);

   xla_events_pub_pkg.g_security := p_security_context;
   xla_events_pub_pkg.g_valuation_method := p_valuation_method;

   RETURN xla_events_pkg.allow_third_party_update
           (p_event_source_info     => p_event_source_info
           ,p_valuation_method      => p_valuation_method);

   trace('< xla_events_pub_pkg.allow_third_party_update'             , C_LEVEL_PROCEDURE);
EXCEPTION
WHEN xla_exceptions_pkg.application_exception THEN
   RAISE;
WHEN OTHERS                                   THEN
   xla_exceptions_pkg.raise_message
      (p_location => 'xla_events_pub_pkg.allow_third_party_update');
END allow_third_party_update;


BEGIN
  g_log_level      := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
  g_log_enabled    := fnd_log.test
                          (log_level  => g_log_level
                          ,MODULE     => C_DEFAULT_MODULE);

  IF NOT g_log_enabled  THEN
    g_log_level := C_LEVEL_LOG_DISABLED;
  END IF;

END xla_events_pub_pkg;
/