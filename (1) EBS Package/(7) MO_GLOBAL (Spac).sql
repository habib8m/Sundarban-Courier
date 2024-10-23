CREATE OR REPLACE PACKAGE APPS.mo_global AUTHID CURRENT_USER AS
/* $Header: AFMOGBLS.pls 120.10.12020000.2 2012/08/13 21:57:04 shnaraya ship $ */

--
-- Name
--   Init
-- Purpose
--   Initialization code for Organization security Policy
--

PROCEDURE init(p_appl_short_name  VARCHAR2);
PROCEDURE init(p_appl_short_name  VARCHAR2, p_sync VARCHAR2);
--
-- Name
--   jtt_init
-- Purpose
--   Initialization code for Organization Security Policy.  This is
--   mainly called from JTT java API's.
--   This will call the init API and will also initialize ICX sesion attribute
--   JTTCURRENTORG when temp table has only one record
--
PROCEDURE jtt_init(p_appl_short_name  IN VARCHAR2,
                   p_icx_session_id   IN NUMBER);

--
-- Name
--   clear_current_org_context
-- Purpose
--   This procedure clears the current org context in database session as
--   well as reset the ICX session attribute JTTCURRENTORG
--
PROCEDURE clear_current_org_context(p_icx_session_id   IN NUMBER);


--
-- Name
--   set_org_access
-- Purpose
--   Sets up the organization access list from MO: Operating Unit and
--   MO: Security Profile
--
-- Arguments
--   p_org_id_char     - the Operating Unit identifier
--
--   p_sp_id_char      - the security profile identifier
--
--   p_appl_short_name - the application owner
--
PROCEDURE set_org_access(p_org_id_char     VARCHAR2,
                         p_sp_id_char      VARCHAR2,
                         p_appl_short_name VARCHAR2);

--
-- Name
--   org_security
-- Purpose
--   Called by oracle server during parsing sql statment
--
-- Arguments
--   obj_schema   - schema of the object
--   obj_name     - name of the object
--

FUNCTION org_security(
  obj_schema          VARCHAR2
, obj_name            VARCHAR2
)
RETURN VARCHAR2;

--
-- Name
--   set_org_context
-- Purpose
--   Wrapper procedure for setting up the Operating Unit context in the client
--   info area and organization access list for Multi-Org Access Control
--
-- Arguments
--   p_org_id_char     - org_id for the operating unit;
--
--   p_sp_id_char      - MO: Security profile id
--
--   p_appl_short_name - the application owner
--
PROCEDURE set_org_context(p_org_id_char     VARCHAR2,
                          p_sp_id_char      VARCHAR2,
                          p_appl_short_name VARCHAR2);

--
-- Name
--   check_access
-- Purpose
--   Checks if an operating unit exists in the PL/SQL array.
--   The PL/SQL array is populated by Multi-Org API set_org_access.
--
-- Arguments
--   p_org_id          - org_id for the operating unit;
--
FUNCTION check_access(p_org_id    NUMBER)
RETURN VARCHAR2;

--
-- Name
--   get_ou_name
-- Purpose
--   This function returns the operating unit name for the org_id parameter
--   passed, if it exists in the PL/SQL array, populated by
--   set_org_access Multi-Org API.
--
-- Arguments
--   p_org_id          - org_id for the Operating Unit;
--
--
FUNCTION get_ou_name(p_org_id    NUMBER)
RETURN VARCHAR2;

--
-- Name
--   check_valid_org
-- Purpose
--   Checks if the specified operating unit exists in the session's
--   access control list. This function is equivalent to the
--   check_access function but also posts an error message if the
--   specified operating unit is null or not in the access list.
--   The calling application can check the returned value of the
--   function and raise an error if it is 'N'.
--
-- Arguments
--   p_org_id         - org_id for the Operating Unit;
--
--
FUNCTION check_valid_org(p_org_id NUMBER) RETURN VARCHAR2;

--
-- Name
--   set_policy_context
-- Purpose
--   Sets the application context for the current org and access mode to
--   be used in server side code for validations as well as in Multi-Org
--   security policy function.
--
-- Arguments
--   p_access_mode     - specifies the operating unit access. 'S' for
--                       Single, 'M' for Multiple, 'A' for All. If null,
--                       the context will be unset.
--   p_org_id          - org_id of the operating unit.
--
PROCEDURE set_policy_context(p_access_mode VARCHAR2,
                             p_org_id      NUMBER);

--
-- Name
--   get_current_org_id
-- Purpose
--   This function returns the current_org_id stored in the application
--   context.
--
FUNCTION get_current_org_id RETURN NUMBER;

--
-- Name
--   get_access_mode
-- Purpose
--   This function returns the access mode stored in the application
--   context.
--
FUNCTION get_access_mode RETURN VARCHAR2;

--
-- Name
--   is_multi_org_enabled
-- Purpose
--   This function determines whether this is a Multi-Org
--   instance or not. Returns 'Y' or 'N'.
--
FUNCTION is_multi_org_enabled RETURN VARCHAR2;

--
-- Name
--   get_ou_count
-- Purpose
--   This function returns the count of the records stored in the Multi-Org
--   temporary table.
--
FUNCTION get_ou_count RETURN NUMBER;

--
-- Index-by tables for storing the identifiers and names of Operating
-- Units.
--
TYPE OrgIdTab  IS TABLE OF hr_operating_units.organization_id%TYPE
  INDEX BY BINARY_INTEGER;
TYPE OuNameTab IS TABLE OF hr_operating_units.name%TYPE
  INDEX BY BINARY_INTEGER;

--
-- A record type that contains information pertinent to an Operating
-- Unit.
--
TYPE OrgInfoRec IS RECORD (
  organization_name hr_operating_units.name%TYPE);

--
-- Name
--   get_valid_org
-- Purpose
--   This function determines and returns the valid ORG_ID.
--
-- If the org_id cannot be passed in, use FND_API.G_MISS_NUM
FUNCTION get_valid_org(p_org_id      NUMBER) RETURN NUMBER;

-- function for public API
PROCEDURE validate_orgid_pub_api(ORG_ID IN OUT NOCOPY NUMBER,
				ERROR_MESG_SUPPR    IN VARCHAR2  DEFAULT 'N',
				STATUS     OUT NOCOPY VARCHAR2);

-- NAME
--   is_mo_init_done
-- Purpose
--   This function checks whether MO init is done or not.
--   Returns 'Y' if initialization is done. Otherwise returns 'N'
--
FUNCTION is_mo_init_done RETURN VARCHAR2;


-- NAME
--    org_security_global
-- Purpose
--    This is a restricted security policy function used to support
--    ORG_ID secured data as well as global data having org_id=-3116.
--    Usage of this policy must be reviewed and approved by MO team.
FUNCTION org_security_global(
  obj_schema          VARCHAR2
, obj_name            VARCHAR2
)
RETURN VARCHAR2;

-- NAME
--  get_ou_tab
-- PURPOSE
--  returns a table of Org Ids that are accessible to the user.
--
FUNCTION get_ou_tab RETURN OrgIdTab;

-- NAME
--   set_policy_context_server
-- PURPOSE
--   Server-side wrapper for set_policy_context API called from Client library
--
PROCEDURE set_policy_context_server(p_access_mode VARCHAR2,
                                    p_org_id      NUMBER);

end mo_global;
/
