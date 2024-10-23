CREATE OR REPLACE PACKAGE BODY APPS.mo_global AS
/* $Header: AFMOGBLB.pls 120.40.12020000.2 2012/08/13 22:00:01 shnaraya ship $ */

  g_multi_org_flag fnd_product_groups.multi_org_flag%TYPE;
  g_access_mode       varchar2(1);
  g_current_org_id    number(15);
  g_ou_count          PLS_INTEGER;
  g_sync              varchar2(1);
  g_init_access_mode varchar2(1);
  g_ou_id_tab OrgIdTab;

  g_old_sp_id fnd_profile_option_values.profile_option_value%TYPE := NULL;
  g_old_org_id fnd_profile_option_values.profile_option_value%TYPE := NULL;
  g_old_user_id NUMBER;
  g_old_resp_id NUMBER;

  TYPE ApplShortNameTab is TABLE OF fnd_mo_product_init.application_short_name%TYPE
  INDEX BY BINARY_INTEGER;
  TYPE StatusTab is TABLE OF fnd_mo_product_init.status%TYPE
  INDEX BY BINARY_INTEGER;

--
-- Private functions and procedures
--
PROCEDURE generic_error(routine in varchar2,
			errcode in number,
			errmsg in varchar2) IS
BEGIN
   fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
   fnd_message.set_token('ROUTINE', routine);
   fnd_message.set_token('ERRNO', errcode);
   fnd_message.set_token('REASON', errmsg);
   IF (FND_LOG.LEVEL_UNEXPECTED >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.MESSAGE(FND_LOG.LEVEL_UNEXPECTED, routine, FALSE);
   END IF;
   fnd_message.raise_error;
END;

--
--   This is an internal API that accepts the ORG_ID, SECURITY_PROFILE_ID
--   and populates the Multi-Org temporary table based on the access
--   enabled status of the product. The API returns the current org for
--   single access mode and view all flag for all access mode.
--
--   Product teams should never access the temporary table directly
--   because it may become obsolete in the future.
--   The contents of the temporary table can be accessed by the
--   APIs provided within this package and the MO_UTILS package.

PROCEDURE populate_orgs (p_org_id_char     IN         VARCHAR2,
                         p_sp_id_char      IN         VARCHAR2,
                         p_current_org_id  OUT NOCOPY VARCHAR2,
                         p_view_all_org    OUT NOCOPY VARCHAR2)
IS

  t_org_id                 OrgidTab;
  t_ou_name                OuNameTab;
  t_common_org_id          OrgidTab;
  t_common_ou_name         OuNameTab;
  t_pref_org_id            OrgidTab;
  t_delete_org_id          OrgidTab;
  sync_ind                 VARCHAR2(1) := 'N';
  match_ind                VARCHAR2(1);
  k                        BINARY_INTEGER := 1;
  l                        BINARY_INTEGER := 1;

  is_view_all_org          VARCHAR2(1);
  l_sp_name                per_security_profiles.security_profile_name%TYPE;
  l_bg_id                  per_security_profiles.business_group_id%TYPE;


  CURSOR c1 IS
    SELECT per.organization_id  organization_id
         , hr.NAME              name
      FROM per_organization_list per
         , hr_operating_units hr
     WHERE per.security_profile_id = to_number(p_sp_id_char)
       AND hr.organization_id = per.organization_id
       AND hr.usable_flag is null;

  CURSOR c2 IS
    SELECT hr.organization_id  organization_id
         , hr.name              name
      FROM hr_operating_units hr
     WHERE hr.organization_id = to_number(p_org_id_char)
       AND hr.usable_flag is null;

  -- Added the following cursor to support view all security profile with a
  -- business group (BG). For a view all security profile within a BG, the
  -- per_organization_list is not populated, so should directly get the
  -- operating units for the particular business group from hr_operating_units
  -- view.

  -- Commented out the reference of the business group name in the WHERE
  -- Clause, since the SQL is supposed to return all operating units under
  -- the business group  (Bug 2720910)

  CURSOR c3 (X_sp_name VARCHAR2,
             X_bg_id   NUMBER) IS
    SELECT hr.organization_id  organization_id
         , hr.name              name
      FROM hr_operating_units hr
     WHERE hr.business_group_id = X_bg_id
       AND hr.usable_flag is null;

  -- Added the following cursor to support global view all security profile
  -- For a global view all security profile, the per_organization_list is
  -- not populated, so should directly get all operating units from
  -- hr_operating_units view.

  CURSOR c4 IS
    SELECT hr.organization_id  organization_id
         , hr.name              name
      FROM hr_operating_units hr
     WHERE hr.usable_flag is null;

  -- Added the following cursor to support synchronization with the multi-org
  -- preference setup.

  CURSOR c5 IS
    SELECT organization_id
      FROM fnd_mo_sp_preferences
     WHERE USER_ID = FND_GLOBAL.USER_ID
       AND RESP_ID = FND_GLOBAL.RESP_ID;

  l_user_id number;
  l_resp_id number;
  l_del_org_id  hr_operating_units.organization_id%TYPE;

BEGIN

   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.begin',
                     'Calling PL/SQL procedure '||
                     'MO_GLOBAL.POPULATE_ORGS');
   END IF;

   --
   -- Initialize the count of the accessible operating units.
   --
   g_ou_count := 0;

   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_STATEMENT,
                     'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.input_parameters',
                     'p_org_id='||p_org_id_char||
                     ', p_sp_id='||p_sp_id_char);
   END IF;

   --
   -- SP ID is NOT NULL and ORG ID is NULL or NOT NULL
   --
   -- Ignore org_id parameter if passed
   --
   IF (p_sp_id_char IS NOT NULL) THEN

      -- Check if this a view all or global view all organizations
      -- security profile. For a view all security profile within
      -- a business group, the business group id is populated.

      SELECT security_profile_name
           , business_group_id
           , view_all_organizations_flag
        INTO l_sp_name
           , l_bg_id
           , p_view_all_org
        FROM per_security_profiles
       WHERE security_profile_id = to_number(p_sp_id_char);

       IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(
           FND_LOG.LEVEL_EVENT,
           'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.config',
           'per_security_profiles.security_profile_name=>'||l_sp_name||
           ', per_security_profiles.business_group_id=>'||l_bg_id||
           ', per_security_profiles.view_all_organizations_flag=>'||is_view_all_org);
       END IF;

       IF (p_view_all_org = 'Y') THEN
         IF (l_bg_id IS NOT NULL) THEN

            -- View all Within the Business Group Case
            IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                              'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.retrieve_orgs_c3_cursor',
                              'Retrieving operating units using cursor c3 with arguments:'||
                              ' l_sp_name='||l_sp_name||
                              ', l_bg_id='||l_bg_id);
            END IF;

            OPEN c3(l_sp_name, l_bg_id);
            LOOP
               FETCH c3 BULK COLLECT
                INTO t_org_id
                   , t_ou_name;
               EXIT WHEN c3%NOTFOUND;
            END LOOP;
            CLOSE c3;

         ELSE

            -- Global View all Case
            IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                              'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.retrieve_orgs_c4_cursor',
                              'Retrieving operating units using cursor c4');
            END IF;

            OPEN c4;
            LOOP
               FETCH c4 BULK COLLECT
                INTO t_org_id
                   , t_ou_name;
               EXIT WHEN c4%NOTFOUND;
            END LOOP;
            CLOSE c4;

         END IF; -- for l_bg_id is not null

      ELSE

         -- Security Profile based on list or hierarchy Case
         IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                           'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.retrieve_orgs_c1_cursor',
                           'Retrieving operating units using cursor c1');
         END IF;

         OPEN c1;
         LOOP
            FETCH c1 BULK COLLECT
             INTO t_org_id
                , t_ou_name;
            EXIT WHEN c1%NOTFOUND;
         END LOOP;
         CLOSE c1;

      END IF; -- for is_view_all_org

   --
   -- SP ID is NULL and ORG ID is NOT NULL
   --
   ELSE
      IF (p_org_id_char is NOT NULL) THEN
         IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                           'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.retrieve_orgs_c2_cursor',
                           'Retrieving operating units using cursor c2');
         END IF;

         OPEN c2;
         LOOP
            FETCH c2 BULK COLLECT
             INTO t_org_id
                , t_ou_name;
            EXIT WHEN c2%NOTFOUND;
         END LOOP;
         CLOSE c2;
      END IF;

   END IF;

   --
   -- Populate Org Information in MO_GLOB_ORG_ACCESS_TMP
   --
   -- Bug fix 4511279
   --   Need to populate temp table even when access mode is "S"
   --
   IF t_org_id.COUNT >= 1 THEN

      OPEN c5;
      LOOP
         FETCH c5 BULK COLLECT
           into t_pref_org_id;
         EXIT WHEN c5%NOTFOUND;
      END LOOP;
      CLOSE c5;

      IF (t_pref_org_id.COUNT > 0) THEN
        IF (g_sync <> 'N') THEN
         sync_ind := 'Y';
        END IF;
         for i in t_pref_org_id.FIRST .. t_pref_org_id.LAST LOOP
            match_ind := 'N';
            for j in t_org_id.FIRST .. t_org_id.LAST LOOP
               if t_pref_org_id(i) = t_org_id(j) then
                  match_ind := 'Y';
                  t_common_org_id(k) := t_org_id(j);
                  t_common_ou_name(k) := t_ou_name(j);
                  k := k+1;
                  exit;
               end if;
            end LOOP;
            if match_ind = 'N' then
               t_delete_org_id(l) := t_pref_org_id(i);
               l := l + 1;
            end if;
         END LOOP;
         -- IF t_delete_org_id.COUNT <> t_pref_org_id.COUNT THEN
         IF (t_delete_org_id.COUNT > 0) THEN
             if ( fnd_adg_support.is_standby )
             then
$if fnd_adg_compile_directive.enable_rpc
$then
               l_user_id := FND_GLOBAL.USER_ID;
               l_resp_id := FND_GLOBAL.RESP_ID;

            FOR m IN t_delete_org_id.FIRST .. t_delete_org_id.LAST LOOP

               l_del_org_id := t_delete_org_id(m);

               delete from FND_MO_SP_PREFERENCES_REMOTE
               where user_id = l_user_id
               and resp_id = l_resp_id
               and organization_id = l_del_org_id;

            END LOOP;
$else
               null;
$end
            else

               FORALL m IN t_delete_org_id.FIRST .. t_delete_org_id.LAST
                  delete from FND_MO_SP_PREFERENCES
                  where user_id = FND_GLOBAL.USER_ID
                  and resp_id = FND_GLOBAL.RESP_ID
                  and organization_id = t_delete_org_id(m);

             end if;

            commit;
         END IF;
      END IF;

      /*
      IF (t_pref_org_id.COUNT > 0) and (g_sync <> 'N') THEN
         sync_ind := 'Y';
         for i in t_org_id.FIRST .. t_org_id.LAST LOOP
            for j in t_pref_org_id.FIRST .. t_pref_org_id.LAST LOOP
               if t_org_id(i) = t_pref_org_id(j) then
                  t_common_org_id(k) := t_org_id(i);
                  t_common_ou_name(k) := t_ou_name(i);
                  k := k+1;
                  exit;
               end if;
            end LOOP;
         end LOOP;
      END IF;
      */

       IF(sync_ind = 'Y') AND ( t_delete_org_id.COUNT < t_pref_org_id.COUNT) THEN
          FOR i IN t_common_org_id.FIRST .. t_common_org_id.LAST LOOP
           if (  fnd_adg_support.is_standby )
           then
$if fnd_adg_compile_directive.enable_rpc
$then
           INSERT
             INTO mo_glob_org_access_tmp_remote
                  (organization_id
                ,  organization_name)
             VALUES (t_common_org_id(i)
                  ,  t_common_ou_name(i));
$else
      null;
$end
           else

           INSERT
             INTO mo_glob_org_access_tmp
                  (organization_id
                ,  organization_name)
             VALUES (t_common_org_id(i)
                  ,  t_common_ou_name(i));
           end if;

-- needed for get_ou_tab function
	     g_ou_id_tab(i):=t_common_org_id(i);
          END LOOP;
       ELSE
          FOR i IN t_org_id.FIRST .. t_org_id.LAST LOOP
           if ( fnd_adg_support.is_standby )
           then
$if fnd_adg_compile_directive.enable_rpc
$then
           INSERT
             INTO mo_glob_org_access_tmp_remote
                  (organization_id
                ,  organization_name)
             VALUES (t_org_id(i)
                  ,  t_ou_name(i));
$else
      null;
$end
           else

           INSERT
             INTO mo_glob_org_access_tmp
                  (organization_id
                ,  organization_name)
             VALUES (t_org_id(i)
                  ,  t_ou_name(i));

           end if;
-- needed for get_ou_tab function
            g_ou_id_tab(i):=t_org_id(i);
          END LOOP;
       END IF;

       g_ou_count := t_org_id.COUNT;

   END IF;

-- set context to 'M' for BG View All Security Profile
   IF p_sp_id_char IS NOT NULL AND l_bg_id IS NOT NULL AND p_view_all_org = 'Y' THEN
      p_view_all_org := 'N';
   END IF;

-- setting  init access mode to S, M or A
   IF p_view_all_org = 'Y' THEN
       g_init_access_mode:='A';
   ELSIF g_ou_count = 1 THEN
      g_init_access_mode:='S';
   ELSIF g_ou_count > 1  THEN
      g_init_access_mode:='M';
   END IF;

   IF g_ou_count = 1 THEN
      p_current_org_id := t_org_id(1);
   END IF;

   IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                        'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.temp_table_insert',
                        'Inserted '||g_ou_count||' record(s) into MO_GLOB_ORG_ACCESS_TMP');
   END IF;

   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.end',
                     'Returning from PL/SQL procedure '||
                     'MO_GLOBAL.POPULATE_ORGS: '||
                     'l_bg_id='||l_bg_id||
                     ', p_sp_id_char='||p_sp_id_char||
                     ', l_sp_name='||l_sp_name||
                     ', p_org_id_char='||p_org_id_char||
                     ', is_view_all_org='||is_view_all_org);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
     IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                             'fnd.plsql.MO_GLOBAL.POPULATE_ORGS.temp_table',
                             'temporary table other exception raised sqlerrm'||
                             '=>'||sqlerrm);
     END IF;
     generic_error('MO_GLOBAL.POPULATE_ORGS', sqlcode, sqlerrm);

END populate_orgs;


--
--   This is an internal API that deletes the temporary table data
--
PROCEDURE delete_orgs
IS
BEGIN
   --
   -- Remove all entries from the session specific temporary table.
   -- Without this, when you switch responsibility you get ORA error
   -- since the repopulation fails because of the unique constraint
   -- violation.
   --

   IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                     'fnd.plsql.MO_GLOBAL.DELETE_ORGS.begin',
                     'Before flushing MO_GLOB_ORG_ACCESS_TMP');
   END IF;

   if ( fnd_adg_support.is_standby )
   then
$if fnd_adg_compile_directive.enable_rpc
$then
      DELETE FROM mo_glob_org_access_tmp_remote;
$else
      null;
$end
   else
      DELETE FROM mo_glob_org_access_tmp;
   end if;

   IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                     'fnd.plsql.MO_GLOBAL.DELETE_ORGS.end',
                     'MO_GLOB_ORG_ACCESS_TMP was flushed');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
     generic_error('MO_GLOBAL.DELETE_ORGS', sqlcode, sqlerrm);

END delete_orgs;

--
-- Public functions and procedures
--

--
-- Name
--   is_multi_org_enabled
-- Purpose
--   This function determines whether this is a multi-org database
--   instance or not. Returns 'Y' or 'N'.
--
FUNCTION is_multi_org_enabled RETURN VARCHAR2
IS

BEGIN
   IF (g_multi_org_flag IS NULL) THEN
      SELECT nvl(multi_org_flag, 'N')
        INTO g_multi_org_flag
        FROM fnd_product_groups;
   END IF;

   RETURN g_multi_org_flag;

EXCEPTION
   WHEN OTHERS THEN
     generic_error('MO_GLOBAL.IS_ACCESS_CONTROL_ENABLED', sqlcode, sqlerrm);
END;

--
-- Name
--   set_org_access
--
-- Purpose
--   This procedure determines which operating units can be accessed
--   from the current database session. It is called by
--   mo_global.init when an Oracle Applications session is started.
--   The parameters passed to set_org_access() are the values of the
--   MO: Operating Unit, MO: Security Profile profile options and
--   Application Owner.
--
--   If the application being initialized can handle more than one
--   Operating Unit, access will be allowed for the Operating Units
--   encompassed by the security profile (if specified) and the value of
--   the Operating Unit parameter will be ignored, provided access is
--   enabled for the application calling this api. If no security profile
--   is specified, access will be initialized for the Operating Unit
--   only. If both are unspecified an exception will be raised. If
--   Application owner is not passed, critical error will be raised.
--
--   The Multi-Org temporary table data is deleted first for all
--   products that call this API.
--   This procedure calls another API (populate_orgs) to populate values
--   in the Multi-Org temporary table when access control is enabled.
--
--   For Inquiry only access control for CRM products, care should be
--   taken during setup to ensure that the Operating Units included in
--   the security profile contain the value specified for the Operating
--   Unit parameter. Otherwise, the user will be able to enter records
--   for the Operating Unit but will not be able to query the same data
--   since read access for CRM is controlled by the security profile.
--
-- Arguments
--   p_org_id_char      - The operating unit ID for the current session
--   p_sp_id_char       - The security profile id for the current session
--   p_appl_short_name  - Application owner for the current module or session
--
PROCEDURE do_set_org_access(p_org_id_char     VARCHAR2,
                         p_sp_id_char      VARCHAR2,
                         p_appl_short_name VARCHAR2)
IS
  l_access_ctrl_enabled    VARCHAR2(1);
  l_security_profile_id    fnd_profile_option_values.profile_option_value%TYPE := p_sp_id_char;
  l_org_id                 fnd_profile_option_values.profile_option_value%TYPE := p_org_id_char;

  l_current_org_id         hr_operating_units.name%TYPE;
  l_view_all_orgs          VARCHAR2(1);

  NO_SP_OU_FOUND           EXCEPTION;
  NO_ORG_ACCESS_FOUND      EXCEPTION;
  NO_APPL_NAME         EXCEPTION;

BEGIN
   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.SET_ORG_ACCESS.begin',
                     'Calling PL/SQL procedure MO_GLOBAL.SET_ORG_ACCESS:'||
                     ' p_org_id_char=>'||p_org_id_char||
                     ', p_sp_id_char=>'||p_sp_id_char||
                     ', p_appl_short_name=>'||p_appl_short_name);
   END IF;

   IF is_multi_org_enabled <> 'Y' THEN
      RETURN;
   END IF;

   IF p_org_id_char IS NULL AND p_sp_id_char IS NULL THEN
     RAISE NO_SP_OU_FOUND;
   ELSIF p_appl_short_name IS NULL THEN
     RAISE NO_APPL_NAME;  -- Should we seed a new mesg ???
   END IF;
   --
   -- Replace this code with 10g shared globals
   --
   BEGIN
     SELECT nvl(mpi.status, 'N')
       INTO l_access_ctrl_enabled
       FROM fnd_mo_product_init mpi
      WHERE mpi.application_short_name = p_appl_short_name;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       fnd_message.set_name('FND','FND_MO_NO_APPL_NAME_FOUND'); -- raise error to
       app_exception.raise_exception;                       -- enforce MO registration
     WHEN OTHERS THEN
       generic_error('MO_GLOBAL.SET_ORG_ACCESS', sqlcode, sqlerrm);
   END;

   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                        'fnd.plsql.MO_GLOBAL.SET_ORG_ACCESS.access_status',
                        'Checking access status within PL/SQL procedure '||
                        'MO_GLOBAL.SET_ORG_ACCESS: '||
                        'l_access_ctrl_enabled=>'||l_access_ctrl_enabled);
   END IF;

   --
   -- Delete temporary table data first for all products access enabled or not
   --
   delete_orgs;
   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                        'fnd.plsql.MO_GLOBAL.SET_ORG_ACCESS.after_delete',
                        'Returning from PL/SQL procedure '||
                        'MO_GLOBAL.DELETE_ORGS ');
   END IF;
   --
   -- For all products, when the access control feature is enabled,
   -- 1. Use the MO: Security Profile if it is set.
   -- 2. Use the MO: Operating Unit if MO: Security Profile is not set
   --
   IF (l_access_ctrl_enabled = 'Y') THEN
     IF l_security_profile_id IS NOT NULL THEN
       l_org_id := null;
     END IF;
     --
     -- Populate temp table
     --
     populate_orgs(l_org_id,
                   l_security_profile_id,
                   l_current_org_id,
                   l_view_all_orgs);
     IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                        'fnd.plsql.MO_GLOBAL.SET_ORG_ACCESS.After_Populate',
                        'Returning from PL/SQL procedure '||
                        'MO_GLOBAL.POPULATE_ORGS ');
     END IF;
     --
     -- Check if you have access to at least one operating unit.
     --
     IF g_ou_count = 0 THEN
       RAISE NO_ORG_ACCESS_FOUND;
     ELSIF g_ou_count = 1 THEN
       --
       -- Set the 'Single' access contexts:
       --
       set_policy_context('S', l_current_org_id);
     ELSE
       --
       -- Added code for All mode to avoid using the policy predicate
       -- when user has access to global view all security profile
       -- Bug (2720892)
       -- Set the access contexts:
       --
       IF l_view_all_orgs = 'Y' THEN
         set_policy_context('A','');
       ELSE
         set_policy_context('M','');
       END IF;
     END IF;
   ELSE
     IF l_org_id IS NOT NULL THEN
        populate_orgs(l_org_id,                 -- Bug4475369 populate
                      null,                     -- 1 ou for S mode for the
                      l_current_org_id,         -- timing being.
                      l_view_all_orgs);
        set_policy_context('S',l_org_id);
     END IF;
   END IF;

   commit;
   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.SET_ORG_ACCESS.end',
                     'Calling PL/SQL procedure MO_GLOBAL.SET_ORG_ACCESS:'||
                     ' p_org_id_char=>'||p_org_id_char||
                     ',p_sp_id_char=>'||p_sp_id_char||
                     ',p_appl_short_name=>'||p_appl_short_name||
                     ',l_view_all_orgs=>'||l_view_all_orgs||
                     ',g_ou_count=>'||g_ou_count);
   END IF;

EXCEPTION
   WHEN NO_ORG_ACCESS_FOUND THEN
     fnd_message.set_name('FND','MO_ORG_ACCESS_NO_DATA_FOUND');
     app_exception.raise_exception;
   WHEN NO_SP_OU_FOUND THEN
     fnd_message.set_name('FND','MO_ORG_ACCESS_NO_SP_OU_FOUND');
     app_exception.raise_exception;
   WHEN NO_APPL_NAME THEN
     app_exception.raise_exception;
   WHEN OTHERS THEN
     generic_error('MO_GLOBAL.SET_ORG_ACCESS', sqlcode, sqlerrm);

END do_set_org_access;

PROCEDURE do_auto_set_org_access(p_org_id_char     VARCHAR2,
                         p_sp_id_char      VARCHAR2,
                         p_appl_short_name VARCHAR2)
IS
  PRAGMA  AUTONOMOUS_TRANSACTION;
begin
  do_set_org_access(p_org_id_char,p_sp_id_char,p_appl_short_name);
end;

PROCEDURE set_org_access(p_org_id_char     VARCHAR2,
                         p_sp_id_char      VARCHAR2,
                         p_appl_short_name VARCHAR2)
IS
begin

  if ( fnd_adg_support.is_standby )
  then
     do_set_org_access(p_org_id_char,p_sp_id_char,p_appl_short_name);
  else
     do_auto_set_org_access(p_org_id_char,p_sp_id_char,p_appl_short_name);
  end if;

end;


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
                   p_icx_session_id   IN NUMBER)
IS
begin
   init(p_appl_short_name,'Y');

   if g_current_org_id is not null
   then
     fnd_session_management.putSessionAttributeValue(p_name        => 'JTTCURRENTORG',
                                                     p_value       => g_current_org_id,
                                                     p_session_id  => p_icx_session_id);
   end if;
end jtt_init;


--
-- Name
--   clear_current_org_context
-- Purpose
--   This procedure clears the current org context in database session as
--   well as reset the ICX session attribute JTTCURRENTORG
--
PROCEDURE clear_current_org_context(p_icx_session_id   IN NUMBER)
IS
BEGIN
  dbms_session.set_context('multi_org2', 'current_org_id', '');
  fnd_session_management.clearSessionAttributeValue(p_name        => 'JTTCURRENTORG',
                                                    p_session_id  => p_icx_session_id);
  g_current_org_id := NULL;
END;

--
-- Name
--   init
-- Purpose
--   Initialization code for Organization Security Policy
--
PROCEDURE init(p_appl_short_name  VARCHAR2)
IS
begin
   init(p_appl_short_name,'Y');
end init;

PROCEDURE init(p_appl_short_name  VARCHAR2, p_sync VARCHAR2)
IS

   l_security_profile_id  fnd_profile_option_values.profile_option_value%TYPE := NULL;
   l_org_id               fnd_profile_option_values.profile_option_value%TYPE := NULL;

BEGIN
   --
   -- Check if multi-org is enabled
   --
   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.INIT.begin',
                     'Calling PL/SQL procedure MO_GLOBAL.INIT');
   END IF;
   IF is_multi_org_enabled = 'Y' THEN
        --
        -- Get the profile values and call set_org_access API
        --
        fnd_profile.get('XLA_MO_SECURITY_PROFILE_LEVEL', l_security_profile_id);
        fnd_profile.get('ORG_ID', l_org_id);

        IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                        'fnd.plsql.MO_GLOBAL.INIT.config',
                        'MO: Operating Unit=>'||l_org_id||
                        ', MO: Security Profile=>'||l_security_profile_id||
                        ', p_appl_short_name=>'||p_appl_short_name);
        END IF;
        IF p_sync = 'Y' THEN
           g_sync := 'Y';
        ELSE
           g_sync := 'N';
        END IF;
        set_org_access(l_org_id, l_security_profile_id, p_appl_short_name);

        -- store profile and org id in global variables
        -- used for checking if new initialization is to be done
        -- in is_mo_init_done API
        g_old_sp_id:=l_security_profile_id;
	IF g_old_sp_id IS NOT NULL THEN
           g_old_org_id:=NULL;
	ELSE
           g_old_org_id:=l_org_id;
	END IF;

   END IF; -- multi org is enabled
   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.INIT.end',
                     'Exiting PL/SQL procedure MO_GLOBAL.INIT');
   END IF;
EXCEPTION
   WHEN others THEN
     generic_error('MO_GLOBAL.INIT', sqlcode, sqlerrm);
END init;


--
-- Name
--   org_security
--
-- Purpose
--   This function implements the security policy for the Multi-Org
--   Access Control mechanism. It is automatically called by the oracle
--   server whenever a secured table or view is referenced by a SQL
--   statement. Products should not call this function directly.
--
--   The security policy function is expected to return a predicate
--   (a WHERE clause) that will control which records can be accessed
--   or modified by the SQL statement. After incorporating the
--   predicate, the server will parse, optimize and execute the
--   modified statement.
--
-- Arguments
--   obj_schema - the schema that owns the secured object
--   obj_name   - the name of the secured object
--
FUNCTION org_security(obj_schema VARCHAR2,
		      obj_name   VARCHAR2) RETURN VARCHAR2
IS
l_ci_debug  fnd_profile_option_values.profile_option_value%TYPE := NULL;
BEGIN

  --
  --  Returns different predicates based on the access_mode
  --  The codes for access_mode are
  --  M - Multiple OU Access
  --  A - All OU Access
  --  S - Single OU Access
  --  Null - Backward Compatibility - CLIENT_INFO case
  --
  --  The Predicates will be appended to Multi-Org synonyms

  IF obj_name = 'AR_PAYMENT_SCHEDULES' and g_access_mode='S' THEN
      RETURN 'org_id = sys_context(''multi_org2'',''current_org_id'') OR (org_id = -3116)';

  ELSIF g_access_mode IS NOT NULL THEN
    IF g_access_mode = 'M' THEN

$if fnd_adg_compile_directive.enable_rpc
$then
      if ( fnd_adg_support.is_standby )
      then
      RETURN 'EXISTS (SELECT  /*+ no_unnest */ 1 --bug 13891445
                        FROM mo_glob_org_access_tmp_remote oa
                       WHERE oa.organization_id = org_id)';
      end if;
$end

      RETURN 'EXISTS (SELECT  /*+ no_unnest */ 1 --bug 13891445
                        FROM mo_glob_org_access_tmp oa
                       WHERE oa.organization_id = org_id)';

    ELSIF g_access_mode in ('A','B') THEN
      RETURN 'org_id <> -3113';           -- Bug5109430 filter seed data from policy predicate
    ELSIF g_access_mode = 'S' THEN
      RETURN 'org_id = sys_context(''multi_org2'',''current_org_id'')';
    ELSIF g_access_mode = 'X' THEN
      RETURN '1 = 2';
    END IF;

  ELSE       -- This section is used reserved for debugging using CLIENT_INFO

   --
   -- Interim solution for MFG teams
   --
   fnd_profile.get('FND_MO_INIT_CI_DEBUG', l_ci_debug);
   IF l_ci_debug = 'Y' THEN
      RETURN 'org_id = substrb(userenv(''CLIENT_INFO''),1,10)';
   ELSE
      RETURN '1=2';
   END IF;

  END IF;

END org_security;


--
-- Name
--   set_org_context
-- Purpose
--   Wrapper procedure for setting up the Operating Unit context in the client
--   info area and organization access list for Multi-Org Access Control for CRM
--   introduced in 11i.1
--
-- Arguments
--   p_org_id_char      - org_id for the operating unit; can be up to 10
--                        bytes long
--   p_sp_id_char       - MO: Security profile id
--   p_appl_short_name  - Application owner for the current module or session
--
PROCEDURE set_org_context(p_org_id_char     VARCHAR2,
                          p_sp_id_char      VARCHAR2,
                          p_appl_short_name VARCHAR2) is

   l_ci_debug  fnd_profile_option_values.profile_option_value%TYPE := NULL;

BEGIN
  IF (FND_LOG.LEVEL_EVENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(FND_LOG.LEVEL_EVENT,
                        'fnd.plsql.MO_GLOBAL.INIT.config',
                        'MO: Operating Unit=>'||p_org_id_char||
                        ',MO: Security Profile=>'||p_sp_id_char||
                        ',p_appl_short_name=>'||p_appl_short_name);
  END IF;

   fnd_profile.get('FND_MO_INIT_CI_DEBUG', l_ci_debug);
   -- Set up the Operating Unit context in the client info area
   IF l_ci_debug = 'Y' THEN
     fnd_client_info.set_org_context(p_org_id_char);
   END IF;

   -- Set up the organization access list for Multi- Org Access Control
   set_org_access(p_org_id_char,p_sp_id_char, p_appl_short_name);

   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.SET_ORG_CONTEXT.end',
                     'Returning from PL/SQL procedure MO_GLOBAL.SET_ORG_CONTEXT');
   END IF;

END set_org_context;


--
-- Name
--   check_access
-- Purpose
--   Checks
--  1. if an Operating Unit exists in the PL/SQL array.
--     The PL/SQL array is populated by the set_org_access Multi-Org API.
--  2. if Operating Unit is same as current org id for 'S'ingle org initialization
--
-- Arguments
--   p_org_id         - org_id for the Operating Unit
--
FUNCTION check_access(p_org_id    NUMBER)
RETURN VARCHAR2 IS

l_org_exists   varchar2(1);

BEGIN
    IF g_access_mode = 'A' THEN
-- if access mode is ALL then return true
          RETURN 'Y';

    ELSIF (GET_OU_COUNT > 1) OR (g_access_mode = 'M') THEN -- added g_access_mode for Bug4575131
-- if mo initialization is done

$if fnd_adg_compile_directive.enable_rpc
$then
      if ( fnd_adg_support.is_standby )
      then

	  SELECT 'Y'
	    INTO l_org_exists
	    FROM mo_glob_org_access_tmp_remote
	   WHERE organization_id = p_org_id;
	  RETURN 'Y';

      end if;
$end

	  SELECT 'Y'
	    INTO l_org_exists
	    FROM mo_glob_org_access_tmp
	   WHERE organization_id = p_org_id;
	  RETURN 'Y';

    ELSIF GET_CURRENT_ORG_ID IS NOT NULL THEN
-- if mo initialization is not done but context is set to 'S'

	  IF P_ORG_ID = GET_CURRENT_ORG_ID THEN
	     RETURN 'Y';
	  END IF;

    END IF;

    RETURN 'N';

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'N';
  WHEN VALUE_ERROR THEN
    RETURN 'N';
END;

--
-- Name
--   get_ou_name
-- Purpose
--   This function returns the Operating Unit name for the org_id parameter
--   passed, if it exists in the temporary table populated by
--   set_org_access Multi-Org API.
--
-- Arguments
--   p_org_id         - org_id for the Operating Unit
--
FUNCTION get_ou_name(p_org_id    NUMBER)
RETURN VARCHAR2 IS

l_ou_name      mo_glob_org_access_tmp.organization_name%TYPE;

BEGIN

$if fnd_adg_compile_directive.enable_rpc
$then
      if ( fnd_adg_support.is_standby )
      then

         SELECT organization_name
           INTO l_ou_name
           FROM mo_glob_org_access_tmp_remote
          WHERE organization_id = p_org_id;
         RETURN l_ou_name;

      end if;
$end

  SELECT organization_name
    INTO l_ou_name
    FROM mo_glob_org_access_tmp
   WHERE organization_id = p_org_id;
  RETURN l_ou_name;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
  WHEN VALUE_ERROR THEN
    RETURN NULL;
END;

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
--   p_org_id         - org_id for the Operating Unit
--
FUNCTION check_valid_org(p_org_id NUMBER) RETURN VARCHAR2
IS

BEGIN
   IF (p_org_id is null) THEN
      -- Post an error message and return:
      fnd_message.set_name('FND', 'MO_ORG_REQUIRED');
      FND_MSG_PUB.ADD;
      RETURN 'N';
   END IF;

   IF (check_access(p_org_id) = 'Y') THEN
      RETURN 'Y';
   END IF;

   -- Post an error message and return:
   fnd_message.set_name('FND', 'MO_ORG_INVALID');
   FND_MSG_PUB.ADD;
   RETURN 'N';
END;

--
-- Name
--   set_policy_context
-- Purpose
--   Sets the application context for the current org and the access
--   mode to be used in server side code for validations as well as in
--   the Multi-Org security policy function.
--
-- Arguments
--   p_access_mode    - specifies the operating unit access. 'S' for
--                      Single, 'M' for Multiple, 'A' for All.
--                    - Access Mode All is resrved for future use.
--                    - X is used to prevent returning any data from synonym
--   p_org_id         - org_id of the operating unit.
--
PROCEDURE set_policy_context(p_access_mode VARCHAR2,
                             p_org_id      NUMBER)
IS

BEGIN
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.SET_POLICY_CONTEXT.begin',
                     'Calling PL/SQL procedure MO_GLOBAL.SET_POLICY_CONTEXT:'||
                     ' p_access_mode=>'||p_access_mode||
                     ',p_org_id=>'||p_org_id);
  END IF;
  --
  -- Get the present values of access mode and current org id
  --
  IF (p_access_mode = g_access_mode
      and p_org_id = g_current_org_id
      and sys_context('multi_org2','current_org_id') = p_org_id) THEN

         NULL;  -- Bug5582505: quick exit if nothing to be reset
  ELSIF (p_access_mode = 'S') THEN
    IF (g_access_mode is NULL OR g_access_mode <> 'S') THEN
      --
      -- If single operating unit access, then mode should be set to 'S'
      --
      dbms_session.set_context('multi_org', 'access_mode', p_access_mode);
      g_access_mode := p_access_mode;
    END IF;
    IF (g_current_org_id IS NULL OR g_current_org_id <> p_org_id
       OR sys_context('multi_org2','current_org_id') <> p_org_id   -- Bug4916086
       OR sys_context('multi_org2','current_org_id') is null) THEN
      --
      -- Set the current org context
      --
      dbms_session.set_context('multi_org2', 'current_org_id', p_org_id);
      g_current_org_id := p_org_id;
      -- Bug 	7227733 Passing current org id to FND
     fnd_global.initialize('ORG_ID',g_current_org_id);

    END IF;

  ELSIF (p_access_mode = 'M') THEN
    IF (g_access_mode is NULL OR g_access_mode <> 'M') THEN
      --
      -- If multiple operating units access, then mode should be set to 'M'
      --
      dbms_session.set_context('multi_org', 'access_mode', p_access_mode);
      g_access_mode := p_access_mode;
    END IF;
    IF (g_current_org_id IS NOT NULL ) THEN
      --
      -- Unset the current org context, since it is not required for multiple
      -- access
      --
      dbms_session.set_context('multi_org2', 'current_org_id', '');
      g_current_org_id := NULL;
       -- Bug 	7227733 Passing current org id to FND
     fnd_global.initialize('ORG_ID',g_current_org_id);
    END IF;

  ELSIF (p_access_mode = 'A') and g_init_access_mode = 'A' THEN
    IF (g_access_mode is NULL OR g_access_mode <> 'A') THEN
      --
      -- If all operating units access, then mode should be set to 'A'
      --
      dbms_session.set_context('multi_org', 'access_mode', p_access_mode);
      g_access_mode := p_access_mode;
    END IF;
    IF (g_current_org_id IS NOT NULL ) THEN
      --
      -- Unset the current org context, since it is not required for all
      -- access
      --
      dbms_session.set_context('multi_org2', 'current_org_id', '');
      g_current_org_id := NULL;
       -- Bug 	7227733 Passing current org id to FND
     fnd_global.initialize('ORG_ID',g_current_org_id);
    END IF;

  ELSIF (p_access_mode in ('X','B')) THEN
      if sys_context('multi_org2','current_org_id') is not null then
         dbms_session.set_context('multi_org2', 'current_org_id', '');
      end if;

      dbms_session.set_context('multi_org', 'access_mode', p_access_mode);
      g_current_org_id := NULL;
      g_access_mode := p_access_mode;

  ELSIF (p_access_mode is NULL) THEN
    IF (g_access_mode IS NOT NULL) THEN
      --
      -- If access_mode is not passed, then unset it
      --
      dbms_session.set_context('multi_org', 'access_mode', p_access_mode);
      g_access_mode := p_access_mode;
    END IF;
    IF (g_current_org_id IS NOT NULL ) THEN
      --
      -- Unset the current org context, since it is not required when mode
      -- is not set
      --
      dbms_session.set_context('multi_org2', 'current_org_id', '');
      g_current_org_id := NULL;
       -- Bug 	7227733 Passing current org id to FND
     fnd_global.initialize('ORG_ID',g_current_org_id);
    END IF;

  END IF;

--
-- store the user and resp. IDs, to be used for checking new OA user session
-- in is_mo_init_done API
--
        g_old_user_id:=sys_context('FND','USER_ID');
        g_old_resp_id:=sys_context('FND','RESP_ID');

  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.SET_POLICY_CONTEXT.end',
                     'Returning from PL/SQL prcedure MO_GLOBAL.SET_POLICY_CONTEXT');
  END IF;

END set_policy_context;

--
-- Name
--   get_current_org_id
-- Purpose
--   This function returns the current_org_id stored in the application
--   context.
--
FUNCTION get_current_org_id RETURN NUMBER
IS

BEGIN
   RETURN to_number(g_current_org_id);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
     RETURN NULL;
   WHEN VALUE_ERROR THEN
     RETURN NULL;
END get_current_org_id;

--
-- Name
--   get_access_mode
-- Purpose
--   This function returns the access mode stored in the application
--   context.
--
FUNCTION get_access_mode RETURN VARCHAR2
IS

BEGIN
   RETURN (g_access_mode);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
     RETURN NULL;
   WHEN VALUE_ERROR THEN
     RETURN NULL;
END get_access_mode;


--
-- Name
--   get_ou_count
-- Purpose
--   This function returns the count of the records stored in the Multi-Org
--   temporary table.
--
FUNCTION get_ou_count RETURN NUMBER
IS

BEGIN
  RETURN (g_ou_count);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
  WHEN VALUE_ERROR THEN
    RETURN 0;
END get_ou_count;

--
-- Name
--   get_valid_org
-- Purpose
--   This function determines and returns the valid ORG_ID.
--
FUNCTION get_valid_org(p_org_id      NUMBER) RETURN NUMBER
IS

  l_org_id           NUMBER;
  l_status           VARCHAR2(1);

BEGIN
  --
  -- Debug information
  --
  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.GET_VALID_ORG.begin',
                     'Calling PL/SQL function '||
                     'MO_GLOBAL.GET_VALID_ORG'||
                     ' p_org_id=>'||p_org_id);
  END IF;

  --
  -- Obtain org ID in the following order:
  --  1. parameter from caller
  --  2. current org ID
  --  3. default org ID
  --
  IF (p_org_id = FND_API.G_MISS_NUM) THEN
    --
    -- If p_org_id is G_MISS_NUM (org id is not passed in), then get the org_id
    -- from current org_id. If that is also not available, get the default
    -- org_id
    --
    l_org_id := NVL(mo_global.get_current_org_id,
                    mo_utils.get_default_org_id);
  ELSE
    --
    -- If p_org_id is null or different from G_MISS_NUM
    -- use explicitly passed in org_id
    --
    l_org_id := p_org_id;
  END IF;

  --
  -- Now validate the org ID
  --
  l_status := check_valid_org(l_org_id);

  --
  --  If the org_id is valid, return it. If it's invalid, return NULL
  --
  IF (l_status = 'N') THEN
    --
    -- Debug information
    --
    IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.GET_VALID_ORG.end',
                     'Returning from PL/SQL function '||
                     'MO_GLOBAL.GET_VALID_ORG:'||
                     ' Returns NULL');
    END IF;

    --
    -- Org_id is invalid
    --
    RETURN NULL;

  ELSE
    --
    -- Debug information
    --
    IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.GET_VALID_ORG.end',
                     'Returning from PL/SQL function '||
                     'MO_GLOBAL.GET_VALID_ORG:'||
                     ' Returns '||l_org_id);
    END IF;

    --
    -- Org_id is valid
    --
    RETURN l_org_id;

  END IF;

EXCEPTION
   WHEN OTHERS THEN
     generic_error('MO_GLOBAL.Get_Valid_Org', sqlcode, sqlerrm);

END get_valid_org;

--  validate_orgid_pub_api
--  to be used in public API's for backword compatibilty
--
--  STATUS is 'S'uccess if org_id passed was
--   1. either valid w/ MO:SP or CURRENT ORG or MO:OU
--    OR
--   2. we have derived from CURRENT ORG or MO:Def OU  or MO:OU
--
--  STATUS is 'F'ailure if org_id passed was
--   1. either invalid w/ both MO:SP and CURRENT ORG and MO:OU
--    OR
--   2. we could not derive that
--
--  To suppress the error pass ERROR_MESG_SUPPR as 'Y'
--   arguments
--  ORG_ID            org_id for Operating Unit
--  ERROR_MESG_SUPPR  error message suppresser
--  STATUS            validation/derivation result
--

PROCEDURE validate_orgid_pub_api(ORG_ID             IN OUT NOCOPY NUMBER,
				ERROR_MESG_SUPPR    IN VARCHAR2  DEFAULT 'N',
				STATUS              OUT NOCOPY VARCHAR2)
IS
l_org_id number(15);
ORG_ID_INVALID_OR_NON_DRV EXCEPTION;

BEGIN


/* May consider the following logic to execute MO init w/in the proc in future.

  IF g_ou_count = 0 AND
     FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL') is NOT NULL THEN
     mo_global.init('M');

  ELSIF g_ou_count = 0 AND
     FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL') is NULL AND
     FND_PROFILE.VALUE('ORG_ID') is NOT NULL THEN
     mo_global.init('S');
  END IF;
*/

  STATUS := 'F'; -- initialize the variable to F

  IF FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL') is NOT NULL
     AND g_ou_count = 0 THEN
        FND_MESSAGE.SET_NAME('FND','FND_MO_NOINIT_SP_PUB_API');
        FND_MSG_PUB.ADD;
        APP_EXCEPTION.RAISE_EXCEPTION;
  END IF;

-- if org_id is passed explicitly
  IF ORG_ID IS NOT NULL AND ORG_ID <> FND_API.G_MISS_NUM THEN
     STATUS:='F';
-- check if org_id passed is valid with
--           1. temp table
--           2. current_org_id
--           3. MO: OU

-- if mo init is done either w/ 'M'ultiple or 'S'ingle
-- check if org_id is valid with orgs in temp table or in the current org

     IF g_ou_count >=1 THEN
       IF CHECK_ACCESS(ORG_ID) = 'Y' THEN
          STATUS:='S';
       ELSE
          IF ERROR_MESG_SUPPR = 'N' THEN
            FND_MESSAGE.SET_NAME('FND','FND_MO_INVALID_OU_API');
            FND_MESSAGE.SET_TOKEN('ORG_NAME', mo_utils.get_org_name(ORG_ID));
            FND_MESSAGE.SET_TOKEN('ORG_ID', ORG_ID);
            FND_MSG_PUB.ADD;
            APP_EXCEPTION.RAISE_EXCEPTION;
          END IF;
      END IF;

     ELSIF FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL') is NULL THEN
        -- mo initialization is not done.
        -- check if org_id passed id valid with MO:OU
        -- for backword compatibilty
        FND_PROFILE.GET('ORG_ID',l_org_id);
        IF ORG_ID = l_org_id THEN
          set_policy_context('S',l_org_id);  -- setting org context for synonym
          STATUS := 'O';

        END IF;

      END IF;

   ELSE  -- org_id value is not passed in explicitly.
         -- try getting the org_id from
         --           1. current org id
         --           2. MO: Def OU
         --           3. MO: OU
    STATUS:='F';
      -- looking here for current org id otherwise default OU
      -- if initialization is done
      IF g_ou_count >= 1 THEN
         ORG_ID := mo_global.get_current_org_id;
         IF ORG_ID is NOT NULL THEN
            STATUS := 'C';
         ELSE
            ORG_ID := GET_VALID_ORG(FND_API.G_MISS_NUM);
            IF ORG_ID is NOT NULL THEN
               STATUS := 'D';
            END IF;
         END IF;

      -- for backword compatibility support. Return status O
      ELSIF FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL') is NULL THEN
        FND_PROFILE.GET('ORG_ID',l_org_id);
        ORG_ID := l_org_id;
        set_policy_context('S',l_org_id);  -- setting org context for synonym
        STATUS := 'O';
      END IF;

    END IF;


IF STATUS='F' AND ERROR_MESG_SUPPR = 'N' THEN
      FND_MESSAGE.SET_NAME('FND','FND_MO_INVALID_OU_PUB_API');
      FND_MSG_PUB.ADD;
      APP_EXCEPTION.RAISE_EXCEPTION;
--     RAISE ORG_ID_INVALID_OR_NON_DRV;
END IF;

EXCEPTION
  WHEN ORG_ID_INVALID_OR_NON_DRV THEN
      FND_MESSAGE.SET_NAME('FND','FND_MO_INVALID_OU_PUB_API');
      APP_EXCEPTION.RAISE_EXCEPTION;
   WHEN others THEN
     STATUS:='F';
     generic_error('MO_GLOBAL.VALIDATE_ORGID_PUB_API', sqlcode, sqlerrm);

END validate_orgid_pub_api;

--  Name: is_mo_init_done
--  Purpose: check if MO initialization is done
--  if OA user session is different then check if SP is same, return Y if same
--  Order is
--  Temp table -> Current Org -> Access Mode (e.g S, M or A)
--

FUNCTION is_mo_init_done RETURN VARCHAR2
IS
l_current_sp_id fnd_profile_option_values.profile_option_value%TYPE := NULL;
l_current_org_id  fnd_profile_option_values.profile_option_value%TYPE := NULL;
l_user_id NUMBER:=NULL;
l_resp_id NUMBER:=NULL;
BEGIN
--
-- bug#5677563 - check for different user sessions, if SP/OU is same
-- if SP is not same application should re-initialize the MOAC
-- hence return 'N'
--

   fnd_profile.get('XLA_MO_SECURITY_PROFILE_LEVEL', l_current_sp_id);
   fnd_profile.get('ORG_ID', l_current_org_id);

   l_user_id:=sys_context('FND','USER_ID');
   l_resp_id:=sys_context('FND','RESP_ID');

   IF (g_ou_count >= 1) THEN
   IF l_current_sp_id IS NOT NULL AND  l_current_sp_id <> FND_API.G_MISS_NUM THEN
     IF nvl(g_old_sp_id,-1) <> l_current_sp_id THEN
      return 'N';
     END IF;
   ELSIF l_current_org_id IS NOT NULL AND l_current_org_id <> FND_API.G_MISS_NUM THEN
     IF nvl(g_old_org_id,-1) <> l_current_org_id THEN
        return 'N';
     END IF;
   ELSE
        return 'N';
   END IF;
   ELSIF( g_current_org_id is not null  OR g_access_mode = 'A' )THEN
        IF (nvl(g_old_user_id,-1) <> l_user_id ) OR (nvl(g_old_resp_id,-1) <> l_resp_id) THEN
            return 'N';
        END IF;
   ELSE
      return 'N';

   IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                 'fnd.plsql.MO_GLOBAL.is_mo_init_done.begin',
                     'g_ou_count=>'||g_ou_count||
                     ', g_access_mode=>'||g_access_mode||
                     ', g_current_org_id=>'||g_current_org_id||
                     ', g_init_access_mode=>'||g_init_access_mode);
     END IF;

   End IF;
   return 'Y';


EXCEPTION
   WHEN OTHERS THEN
     generic_error('MO_GLOBAL.IS_MO_INIT_DONE', sqlcode, sqlerrm);
END is_mo_init_done;

-- Name
--    org_security_global function
-- Purpose
--    This is a restricted policy function to support global data -3116.
FUNCTION org_security_global(obj_schema VARCHAR2,
                      obj_name   VARCHAR2) RETURN VARCHAR2
IS
l_ci_debug  fnd_profile_option_values.profile_option_value%TYPE := NULL;
BEGIN

  --
  --  Returns different predicates based on the access_mode
  --  The codes for access_mode are
  --  M - Multiple OU Access
  --  A - All OU Access
  --  S - Single OU Access
  --  Null - Backward Compatibility - CLIENT_INFO case
  --
  --  The Predicates will be appended to Multi-Org synonyms

  IF g_access_mode IS NOT NULL THEN
    IF g_access_mode = 'S' THEN
       RETURN 'org_id = sys_context(''multi_org2'',''current_org_id'') OR (org_id = -3116)';

    ELSIF g_access_mode = 'M' THEN

$if fnd_adg_compile_directive.enable_rpc
$then
      if ( fnd_adg_support.is_standby )
      then
        RETURN '(EXISTS (SELECT 1
                      FROM mo_glob_org_access_tmp_remote oa
                      WHERE oa.organization_id = org_id))
                 OR (org_id = -3116)';
      end if;
$end
        RETURN '(EXISTS (SELECT 1
                      FROM mo_glob_org_access_tmp oa
                      WHERE oa.organization_id = org_id))
                 OR (org_id = -3116)';
    ELSIF g_access_mode in ('A','B') THEN
      RETURN 'org_id <> -3113';           -- Bug5109430 filter seed data from policy predicate
    ELSIF g_access_mode = 'X' THEN
      RETURN '1 = 2';

    END IF;

  ELSE
   --
   -- Interim solution for MFG teams
   --
   fnd_profile.get('FND_MO_INIT_CI_DEBUG', l_ci_debug);
   IF l_ci_debug = 'Y' THEN
      RETURN 'org_id = substrb(userenv(''CLIENT_INFO''),1,10)';
   ELSE
      RETURN '1=2';
   END IF;

  END IF;

END org_security_global;

--
-- Name
--   get_ou_tab
-- Purpose
--   This function returns a table that contains the
--   identifiers of all the accessible operating units.
--
FUNCTION get_ou_tab RETURN OrgIdTab
IS
BEGIN
--  use memory instead of hitting the table
--  select organization_id BULK COLLECT INTO l_ou_id_tab from mo_glob_org_access_tmp;
   RETURN g_ou_id_tab;
END get_ou_tab;

--
-- Name
--   set_policy_context_server
-- Purpose
--   This wrapper is called from Forms client-side library to synchronize
--   current_org_id variable w/ :GLOBAL.current_org_id when set_policy_context
--   API is invoked in Forms.
--
PROCEDURE set_policy_context_server(p_access_mode VARCHAR2,
                                    p_org_id      NUMBER)
IS

BEGIN

  IF (FND_LOG.LEVEL_PROCEDURE >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(FND_LOG.LEVEL_PROCEDURE,
                     'fnd.plsql.MO_GLOBAL.SET_POLICY_CONTEXT_SERVER.begin',
                     'Calling PL/SQL procedure MO_GLOBAL.SET_POLICY_CONTEXT_SERVER:'||
                     ' p_access_mode=>'||p_access_mode||
                     ',p_org_id=>'||p_org_id);
  END IF;

  MO_GLOBAL.set_policy_context(p_access_mode, p_org_id); -- Force server-side to sync

END set_policy_context_server;

--
-- Name
--   populate_organizations
-- Purpose
--   This is a wrapper API to populate_orgs called
--   from FND_CONCURRENT API. Not to be used for
--   any other purpose
--


Procedure populate_organizations(p_org_id_char     IN         VARCHAR2,
                         p_sp_id_char      IN         VARCHAR2,
                         p_current_org_id  OUT NOCOPY VARCHAR2,
                         p_view_all_org    OUT NOCOPY VARCHAR2)

IS
BEGIN

populate_orgs (p_org_id_char,
                         p_sp_id_char,
                         p_current_org_id,
                         p_view_all_org);
END populate_organizations;


--
-- Name
--   delete_organizations
-- Purpose
--   This is a wrapper API to delete_orgs called
--   from FND_CONCURRENT API. Not to be used for
--   any other purpose
--
PROCEDURE delete_organizations
IS
BEGIN
delete_orgs;

END delete_organizations;


END mo_global;
/