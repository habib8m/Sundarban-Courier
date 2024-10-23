CREATE OR REPLACE PACKAGE APPS.xla_events_pub_pkg AUTHID CURRENT_USER AS
-- $Header: xlaevevp.pkh 120.35 2010/10/13 12:53:14 nksurana ship $
/*===========================================================================+
|             Copyright (c) 2001-2002 Oracle Corporation                     |
|                       Redwood Shores, CA, USA                              |
|                         All rights reserved.                               |
+============================================================================+
| FILENAME                                                                   |
|    xlaevevp.pkh                                                            |
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
|    17-Jul-01 P. Labrevois    Added array w/ id                             |
|    14-Sep-01 P. Labrevois    Added 2nd bulk                                |
|    08-Feb-02 S. Singhania    Reviewed and performed major changes          |
|    10-Feb-02 S. Singhania    Made changes in APIs to handle 'Transaction   |
|                               Number' (new column added in xla_entities)   |
|    13-Feb-02 S. Singhania    Made changes in APIs to handle 'Event Number' |
|    17-Feb-02 S. Singhania    Added 'Org_id' parameter to all the APIs as a |
|                               'security context'                           |
|    04-Apr-02 S. Singhania    Replaced 'Org_id' parameter with the generic  |
|                                paramenter 'p_security_context'. Removed the|
|                                not required, redundant APIs                |
|    17-Apr-02 S. Singhania    Removed type "t_entity_source_info" and shadow|
|                                procedures. Added type "t_security". Added  |
|                                seperate APIs to update transaction number, |
|                                Event Number and Reference Information      |
|    06-May-02 S. Singhania    Added "valuation_method" and "ledger_id"      |
|                                Bug # 2351677                               |
|    31-May-02 S. Singhania    Changes based on Bug # 2392835. Changed type  |
|                                definitions to remove 'source_id_date_n'.   |
|                              Removed one of the 'create_entity_event' API  |
|                              Renamed 'create_entity_event' API to          |
|                                'create_bulk_events'                        |
|    23-Jul-02 S. Singhania    commented 'document status' contants and the  |
|                                'get_document_status' API. Bug # 2464825    |
|    09-Sep-02 S. Singhania    Made changes to resolve bug # 2530796.        |
|                                Modified signature of 'create_bulk_events', |
|                                added types 't_entity_event_info_s' and     |
|                                't_array_entity_event_info_s'               |
|    04-Sep-03 S. Singhania    Made changes to satisfy enhanced requirement  |
|                                for 'Source Application'.                   |
|                                - Modified the type T_EVENT_SOURCE_INFO     |
|                                - Added parameter to CREATE_BULK_EVENTS     |
|    12-Dec-03 S. Singhania    Removed the API UPDATE_TRANSACTION_NUMBER.    |
|                                Bug # 3268790                               |
|                                                                            |
|    23-Mar-04 W. Shen         add on_hold_flag to t_event_info              |
|    25-Jun-04 W. Shen         add a new function delete_entity(bug 3316535) |
|    23-OCT-04 W. Shen         New API to delete/update/create event in bulk |
|    4 -Apr-05 W. Shen         add transaction_date to the new update_event  |
|                                API and create_event API                    |
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

-------------------------------------------------------------------------------
-- declaring global constants
-------------------------------------------------------------------------------
C_EVENT_PROCESSED          CONSTANT  VARCHAR2(1)  := 'P';   -- The status will never be be used by product team.
C_EVENT_UNPROCESSED        CONSTANT  VARCHAR2(1)  := 'U';   -- event status:unprocessed
C_EVENT_INCOMPLETE         CONSTANT  VARCHAR2(1)  := 'I';   -- event status:incomplete
C_EVENT_NOACTION           CONSTANT  VARCHAR2(1)  := 'N';   -- event status:noaction

-------------------------------------------------------------------------------
-- declaring global types
-------------------------------------------------------------------------------
--
-- Type that store security context for an entity/document
--
TYPE t_security IS RECORD
  (security_id_int_1              INTEGER
  ,security_id_int_2              INTEGER
  ,security_id_int_3              INTEGER
  ,security_id_char_1             VARCHAR2(30)
  ,security_id_char_2             VARCHAR2(30)
  ,security_id_char_3             VARCHAR2(30));

--
-- Source IDs information for an entity/document
--
TYPE t_event_source_info IS RECORD
  (source_application_id          PLS_INTEGER    DEFAULT NULL
  ,application_id                 PLS_INTEGER
  ,legal_entity_id                PLS_INTEGER
  ,ledger_id                      PLS_INTEGER
  ,entity_type_code               VARCHAR2(30)
  ,transaction_number             VARCHAR2(240)
  ,source_id_int_1                NUMBER
  ,source_id_int_2                NUMBER
  ,source_id_int_3                NUMBER
  ,source_id_int_4                NUMBER
  ,source_id_char_1               VARCHAR2(30)
  ,source_id_char_2               VARCHAR2(30)
  ,source_id_char_3               VARCHAR2(30)
  ,source_id_char_4               VARCHAR2(30));

--  ,source_id_date_1               DATE
--  ,source_id_date_2               DATE
--  ,source_id_date_3               DATE
--  ,source_id_date_4               DATE);

--
-- Reference-only infos for an event
--
TYPE t_event_reference_info IS RECORD
  (reference_num_1                NUMBER
  ,reference_num_2                NUMBER
  ,reference_num_3                NUMBER
  ,reference_num_4                NUMBER
  ,reference_char_1               VARCHAR2(240)
  ,reference_char_2               VARCHAR2(240)
  ,reference_char_3               VARCHAR2(240)
  ,reference_char_4               VARCHAR2(240)
  ,reference_date_1               DATE
  ,reference_date_2               DATE
  ,reference_date_3               DATE
  ,reference_date_4               DATE);

--
-- Information for an event, by event_id
--
TYPE t_event_info IS RECORD
  (event_id                       NUMBER -- 8761772
  ,event_number                   PLS_INTEGER
  ,event_type_code                VARCHAR2(30)
  ,event_date                     DATE
  ,event_status_code              VARCHAR2(1)
  ,process_status_code            VARCHAR2(1)
  ,on_hold_flag                   VARCHAR2(1)
  ,reference_num_1                NUMBER
  ,reference_num_2                NUMBER
  ,reference_num_3                NUMBER
  ,reference_num_4                NUMBER
  ,reference_char_1               VARCHAR2(240)
  ,reference_char_2               VARCHAR2(240)
  ,reference_char_3               VARCHAR2(240)
  ,reference_char_4               VARCHAR2(240)
  ,reference_date_1               DATE
  ,reference_date_2               DATE
  ,reference_date_3               DATE
  ,reference_date_4               DATE);

--
-- Information for an event, by event_id, <L>imited to major members
--
TYPE t_event_info_l IS RECORD
  (event_id                       NUMBER -- 8761772
  ,event_type_code                VARCHAR2(30)
  ,event_date                     DATE
  ,event_status_code              VARCHAR2(1)
  ,process_status_code            VARCHAR2(1));

--
-- Full information for an event, by source both source IDs and event_id
--
TYPE t_entity_event_info IS RECORD
  (event_type_code                VARCHAR2(30)
  ,event_date                     DATE
  ,event_id                       NUMBER -- 8761772
  ,event_number                   PLS_INTEGER
  ,event_status_code              VARCHAR2(1)
  ,transaction_number             VARCHAR2(240)
  ,transaction_date               DATE
  ,source_id_int_1                NUMBER
  ,source_id_int_2                NUMBER
  ,source_id_int_3                NUMBER
  ,source_id_int_4                NUMBER
  ,source_id_char_1               VARCHAR2(30)
  ,source_id_char_2               VARCHAR2(30)
  ,source_id_char_3               VARCHAR2(30)
  ,source_id_char_4               VARCHAR2(30)
  ,reference_num_1                NUMBER
  ,reference_num_2                NUMBER
  ,reference_num_3                NUMBER
  ,reference_num_4                NUMBER
  ,reference_char_1               VARCHAR2(240)
  ,reference_char_2               VARCHAR2(240)
  ,reference_char_3               VARCHAR2(240)
  ,reference_char_4               VARCHAR2(240)
  ,reference_date_1               DATE
  ,reference_date_2               DATE
  ,reference_date_3               DATE
  ,reference_date_4               DATE);

--  ,source_id_date_1               DATE
--  ,source_id_date_2               DATE
--  ,source_id_date_3               DATE
--  ,source_id_date_4               DATE

TYPE t_entity_event_info_s IS RECORD
  (event_type_code                VARCHAR2(30)
  ,event_date                     DATE
  ,event_id                       NUMBER -- 8761772
  ,event_number                   PLS_INTEGER
  ,event_status_code              VARCHAR2(1)
  ,transaction_number             VARCHAR2(240)
  ,transaction_date               DATE
  ,source_id_int_1                NUMBER
  ,source_id_int_2                NUMBER
  ,source_id_int_3                NUMBER
  ,source_id_int_4                NUMBER
  ,source_id_char_1               VARCHAR2(30)
  ,source_id_char_2               VARCHAR2(30)
  ,source_id_char_3               VARCHAR2(30)
  ,source_id_char_4               VARCHAR2(30)
  ,reference_num_1                NUMBER
  ,reference_num_2                NUMBER
  ,reference_num_3                NUMBER
  ,reference_num_4                NUMBER
  ,reference_char_1               VARCHAR2(240)
  ,reference_char_2               VARCHAR2(240)
  ,reference_char_3               VARCHAR2(240)
  ,reference_char_4               VARCHAR2(240)
  ,reference_date_1               DATE
  ,reference_date_2               DATE
  ,reference_date_3               DATE
  ,reference_date_4               DATE
  ,valuation_method               VARCHAR2(30)
  ,budgetary_control_flag         VARCHAR2(1)
  ,security_id_int_1              INTEGER
  ,security_id_int_2              INTEGER
  ,security_id_int_3              INTEGER
  ,security_id_char_1             VARCHAR2(30)
  ,security_id_char_2             VARCHAR2(30)
  ,security_id_char_3             VARCHAR2(30));


TYPE t_array_event_reference_info IS TABLE OF t_event_reference_info  INDEX BY BINARY_INTEGER;
TYPE t_array_event_info           IS TABLE OF t_event_info            INDEX BY BINARY_INTEGER;
TYPE t_array_event_info_l         IS TABLE OF t_event_info_l          INDEX BY BINARY_INTEGER;
TYPE t_array_event_source_info    IS TABLE OF t_event_source_info     INDEX BY BINARY_INTEGER;
TYPE t_array_event_type           IS TABLE OF VARCHAR2(30)            INDEX BY BINARY_INTEGER;
TYPE t_array_event_date           IS TABLE OF DATE                    INDEX BY BINARY_INTEGER;
TYPE t_array_event_status_code    IS TABLE OF VARCHAR2(1)             INDEX BY BINARY_INTEGER;
TYPE t_array_entity_id            IS TABLE OF NUMBER                  INDEX BY BINARY_INTEGER; -- 8761772
TYPE t_array_event_id             IS TABLE OF NUMBER                  INDEX BY BINARY_INTEGER; -- 8761772
TYPE t_array_entity_event_info    IS TABLE OF t_entity_event_info     INDEX BY BINARY_INTEGER;
TYPE t_array_entity_event_info_s  IS TABLE OF t_entity_event_info_s   INDEX BY BINARY_INTEGER;
TYPE t_array_event_number         IS TABLE OF NUMBER                  INDEX BY BINARY_INTEGER;


-------------------------------------------------------------------------------
-- declaring global variables
-------------------------------------------------------------------------------

g_security                        t_security;
g_valuation_method                VARCHAR2(30);
-------------------------------------------------------------------------------
-- Event creation routines
-------------------------------------------------------------------------------

FUNCTION create_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_type_code              IN  VARCHAR2
   ,p_event_date                   IN  DATE
   ,p_event_status_code            IN  VARCHAR2
   ,p_event_number                 IN  INTEGER     DEFAULT NULL
   ,p_transaction_date             IN  DATE        DEFAULT NULL
   ,p_reference_info               IN  xla_events_pub_pkg.t_event_reference_info DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN INTEGER;

FUNCTION create_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_type_code              IN  VARCHAR2
   ,p_event_date                   IN  DATE
   ,p_event_status_code            IN  VARCHAR2
   ,p_event_number                 IN  INTEGER     DEFAULT NULL
   ,p_transaction_date             IN  DATE        DEFAULT NULL
   ,p_reference_info               IN  xla_events_pub_pkg.t_event_reference_info DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_budgetary_control_flag       IN  VARCHAR2)
RETURN INTEGER;


-------------------------------------------------------------------------------
-- Event updation routines
-------------------------------------------------------------------------------

PROCEDURE update_event_status
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security);

PROCEDURE update_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_transaction_date             IN  DATE       DEFAULT NULL);

PROCEDURE update_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_event_number                 IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_transaction_date             IN  DATE       DEFAULT NULL);

PROCEDURE update_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_reference_info               IN  xla_events_pub_pkg.t_event_reference_info
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_transaction_date             IN  DATE       DEFAULT NULL);

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
   ,p_transaction_date             IN  DATE       DEFAULT NULL);

-------------------------------------------------------------------------------
-- Event deletion routines
-------------------------------------------------------------------------------

PROCEDURE delete_event
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security);

FUNCTION delete_events
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN INTEGER;

-------------------------------------------------------------------------------
-- Event information routines
-------------------------------------------------------------------------------

FUNCTION get_event_info
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN xla_events_pub_pkg.t_event_info;

FUNCTION get_event_status
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_id                     IN  INTEGER
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN VARCHAR2;

FUNCTION event_exists
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_event_number                 IN  INTEGER    DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN BOOLEAN;

FUNCTION get_array_event_info
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_event_class_code             IN  VARCHAR2   DEFAULT NULL
   ,p_event_type_code              IN  VARCHAR2   DEFAULT NULL
   ,p_event_date                   IN  DATE       DEFAULT NULL
   ,p_event_status_code            IN  VARCHAR2   DEFAULT NULL
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN xla_events_pub_pkg.t_array_event_info;
-------------------------------------------------------------------------------
-- Entity deletion routines
-------------------------------------------------------------------------------

FUNCTION delete_entity
   (p_source_info                  IN  xla_events_pub_pkg.t_event_source_info
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN INTEGER;

FUNCTION period_close
   (p_subscription_guid    IN raw
   ,p_event                IN OUT NOCOPY  WF_EVENT_T)
RETURN VARCHAR2;

PROCEDURE period_close
   (p_api_version    IN NUMBER
   ,x_return_status  IN OUT NOCOPY VARCHAR2
   ,p_application_id IN NUMBER
   ,p_ledger_id      IN NUMBER
   ,p_period_name    IN VARCHAR2);

PROCEDURE create_bulk_events
       (p_source_application_id        IN  INTEGER     DEFAULT NULL
       ,p_application_id               IN  INTEGER
       ,p_legal_entity_id              IN  INTEGER     DEFAULT NULL
       ,p_ledger_id                    IN  INTEGER
       ,p_entity_type_code             IN  VARCHAR2);


PROCEDURE create_bulk_events
       (p_source_application_id        IN  INTEGER     DEFAULT NULL
       ,p_application_id               IN  INTEGER
       ,p_legal_entity_id              IN  INTEGER     DEFAULT NULL
       ,p_ledger_id                    IN  INTEGER
       ,p_entity_type_code             IN  VARCHAR2
       ,p_limit_size                   IN  INTEGER);


PROCEDURE update_bulk_event_statuses(p_application_id INTEGER);
PROCEDURE update_bulk_event_statuses(p_application_id                IN  INTEGER
                                     ,p_limit_size                   IN  INTEGER);

PROCEDURE delete_bulk_events(p_application_id INTEGER);


--added bug6737299 update transaction number procedure

-------------------------------------------------------------------------------
-- Entity update routines
-------------------------------------------------------------------------------

PROCEDURE update_transaction_number
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_transaction_number           IN  VARCHAR2
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security
   ,p_event_id                     IN  NUMBER  DEFAULT NULL) ; -- 8761772

-------------------------------------------------------------------------------
-- Control Account Information routines
-------------------------------------------------------------------------------

FUNCTION allow_third_party_update
   (p_event_source_info            IN  xla_events_pub_pkg.t_event_source_info
   ,p_valuation_method             IN  VARCHAR2
   ,p_security_context             IN  xla_events_pub_pkg.t_security)
RETURN BOOLEAN;

END xla_events_pub_pkg;
/
