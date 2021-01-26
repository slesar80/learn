/*Create Package TEST.ADDRESS_UTILS*/

--Grant select to tables UMMS_BUFFER (выполнять в схеме UMMS_BUFFER)
GRANT SELECT ON dict_address_object TO TEST;
GRANT SELECT ON dict_address_object_type TO TEST;

--Create Synonym to tables UMMS_BUFFER (выполнять в схеме TEST)
CREATE OR REPLACE SYNONYM dict_address_object FOR umms_buffer.dict_address_object;
CREATE OR REPLACE SYNONYM dict_address_object_type FOR umms_buffer.dict_address_object_type;

--Create package TEST.ADDRESS_UTILS (выполнять в схеме TEST)
CREATE OR REPLACE PACKAGE TEST.ADDRESS_UTILS IS
   RUSSIA_ID CONSTANT NUMBER:= 1033362;
--------------------------------------------------------------------------------
   FUNCTION GET_CONCAT_SETTLEMENT (START_ID  IN NUMBER,
                                   DIRECTION IN PLS_INTEGER) RETURN VARCHAR2;
END ADDRESS_UTILS;
/

CREATE OR REPLACE PACKAGE BODY TEST.ADDRESS_UTILS IS
   INVALID_HOUSING_TYPES      EXCEPTION;

   C_SUB_REGION               CONSTANT PLS_INTEGER:= 2;
   C_CITY                     CONSTANT PLS_INTEGER:= 3;
   C_TOWN                     CONSTANT PLS_INTEGER:= 4;
   C_SETTLEMENT               CONSTANT PLS_INTEGER:= 34;
   C_STREET                   CONSTANT PLS_INTEGER:= 5;
   C_SUBORDINATE_90           CONSTANT PLS_INTEGER:= 90;
   C_SUBORDINATE_91           CONSTANT PLS_INTEGER:= 91;
   C_HOUSE                    CONSTANT PLS_INTEGER:= 6;
   C_CORPSE                   CONSTANT PLS_INTEGER:= 7;
   C_BUILDING                 CONSTANT PLS_INTEGER:= 8;
   C_FLAT                     CONSTANT PLS_INTEGER:= 9;
   C_ROOM                     CONSTANT PLS_INTEGER:= 10;
   C_COMMA_SPACE_SEPARATOR    CONSTANT VARCHAR2(2):= ', ';
   C_SPACE_SEPARATOR          CONSTANT VARCHAR2(1):= ' ';

   TYPE HOUSING_RECORD_TYPE IS RECORD (existance_flag PLS_INTEGER,
                                       id             NUMBER,
                                       type_1_id      NUMBER,
                                       type_2_id      NUMBER,
                                       type_3_id      NUMBER,
                                       type_4_id      NUMBER,
                                       type_5_id      NUMBER,
                                       type_6_id      NUMBER,
                                       type_7_id      NUMBER,
                                       type_8_id      NUMBER,
                                       value_1        VARCHAR2(50),
                                       value_2        VARCHAR2(50),
                                       value_3        VARCHAR2(50),
                                       value_4        VARCHAR2(50),
                                       value_5        VARCHAR2(50),
                                       value_6        VARCHAR2(50),
                                       value_7        VARCHAR2(50),
                                       value_8        VARCHAR2(50));

   TYPE TYPE_CORE_ADDRESS_RECORD IS RECORD (existance_flag PLS_INTEGER,
                                            id             NUMBER);

   TYPE TYPE_HOUSING_TVAL_RECORD IS RECORD (TYPE_ID    NUMBER,
                                            TYPE_VAL   VARCHAR2(50));
   TYPE TYPE_HOUSING_VARRAY IS VARRAY(8) OF TYPE_HOUSING_TVAL_RECORD;
--------------------------------------------------------------------------------
   FUNCTION GET_CONCAT_SETTLEMENT (START_ID  IN NUMBER,
                                   DIRECTION IN PLS_INTEGER) RETURN VARCHAR2 AS
   -- Возвращает полный путь в иерархии адресного объекта START_ID
   -- DIRECTION - направление (0 - прямое, 1 - обратное)
      str     VARCHAR2(4000);
      delim   VARCHAR2(2):= ', ';
   BEGIN
      IF DIRECTION = 1 THEN
         FOR rec IN (SELECT (SELECT p.aot_abbreviation
                               FROM dict_address_object_type p
                              WHERE p.aot_id = b.aob_type_id) || ' ' ||
                            b.aob_name AS settl_name
                       FROM dict_address_object b
                      WHERE b.aob_hierarchy_level > 0
                      START WITH b.aob_id = start_id
                    CONNECT BY PRIOR b.aob_parent_id = b.aob_id
                      ORDER BY b.aob_hierarchy_level)
         LOOP
            str:= str || delim || rec.settl_name;
         END LOOP;

      ELSE
         FOR rec IN (SELECT (SELECT p.aot_abbreviation
                               FROM dict_address_object_type p
                              WHERE p.aot_id = b.aob_type_id) || ' ' ||
                            b.aob_name AS settl_name
                       FROM dict_address_object b
                      WHERE b.aob_hierarchy_level > 0
                      START WITH b.aob_id = start_id
                    CONNECT BY PRIOR b.aob_parent_id = b.aob_id)
         LOOP
            str:= str || delim || rec.settl_name;
         END LOOP;
      END IF;
      str:= SUBSTR(str, LENGTH(delim));

      RETURN TRIM(str);
   END get_concat_settlement;

END ADDRESS_UTILS;
/

/***********************************************************************************************************************************************************************************************************/

/*Create Package TEST.CORE_UTILS*/

--Grant select to tables UMMS_BUFFER (выполнять в схеме UMMS_BUFFER)

GRANT SELECT ON core_org_statestatus  TO TEST;
GRANT SELECT ON core_org_operation TO TEST;
GRANT SELECT ON core_org_case TO TEST;
GRANT SELECT ON core_personstatestatus TO TEST;
GRANT SELECT ON core_operation TO TEST;
GRANT SELECT ON core_person_case TO TEST;

--Create Synonym to tables UMMS_BUFFER (выполнять в схеме TEST)

CREATE OR REPLACE SYNONYM core_org_statestatus FOR umms_buffer.core_org_statestatus;
CREATE OR REPLACE SYNONYM core_org_operation FOR umms_buffer.core_org_operation;
CREATE OR REPLACE SYNONYM core_org_case FOR umms_buffer.core_org_case;
CREATE OR REPLACE SYNONYM core_personstatestatus FOR umms_buffer.core_personstatestatus;
CREATE OR REPLACE SYNONYM core_operation FOR umms_buffer.core_operation;
CREATE OR REPLACE SYNONYM core_person_case FOR umms_buffer.core_person_case;

-- Cоздание вспомогательных объктов для компиляции вспомогательного пакета: TEST.tools (выполнять в схеме TEST)

CREATE SEQUENCE TEST.ERROR_LOG_SEQ
  START WITH 285945
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;

CREATE TABLE TEST.ERROR_LOG
(
  ERL_ID         NUMBER CONSTRAINT NN_ERRORLOG_ID NOT NULL,
  ERL_DATETIME   TIMESTAMP(6) CONSTRAINT NN_ERRORLOG_DATETIME NOT NULL,
  ERL_PLACE      VARCHAR2(100 BYTE) CONSTRAINT NN_ERRORLOG_PLACE NOT NULL,
  ERL_PARAMETER  VARCHAR2(250 BYTE),
  ERL_MESSAGE    VARCHAR2(250 BYTE)
)
TABLESPACE UMMS_BUFFER
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          8M
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;

COMMENT ON TABLE TEST.ERROR_LOG IS 'Журнал регистрации ошибок уровня БД';

COMMENT ON COLUMN TEST.ERROR_LOG.ERL_ID IS 'Идентификатор ошибки';

COMMENT ON COLUMN TEST.ERROR_LOG.ERL_DATETIME IS 'Дата и время возникновения ошибки';

COMMENT ON COLUMN TEST.ERROR_LOG.ERL_PLACE IS 'Место возникновения ошибки';

COMMENT ON COLUMN TEST.ERROR_LOG.ERL_PARAMETER IS 'Связанные параметры';

COMMENT ON COLUMN TEST.ERROR_LOG.ERL_MESSAGE IS 'Дополнительная информация';


CREATE UNIQUE INDEX TEST.PK_ERRORLOG ON TEST.ERROR_LOG
(ERL_ID)
LOGGING
TABLESPACE UMMS_BUFFER
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          704K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

CREATE OR REPLACE TRIGGER TEST.TRG_ERRORLOG_BINS
BEFORE INSERT ON TEST.ERROR_LOG
FOR EACH ROW
BEGIN
    SELECT ERROR_LOG_SEQ.NEXTVAL INTO :NEW.ERL_ID FROM DUAL;
END;
/

--Эта конструкция не отработала, однако она не отработала и на источнике ППОТ*/
/*ALTER TABLE TEST.ERROR_LOG ADD (
  CONSTRAINT PK_ERRORLOG
  PRIMARY KEY
  (ERL_ID)
  USING INDEX TEST.PK_ERRORLOG
  ENABLE VALIDATE);*/

--Create package TOOLS.ERROR_PROCESSING (выполнять в схеме TEST)

CREATE OR REPLACE PACKAGE TEST.TOOLS AS
   TYPE ID_ARRAY  IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

   MANDATORY_PARAMETERS            EXCEPTION;
   INVALID_INPUT_PARAMETERS        EXCEPTION;
   INVALID_INSTANCE                EXCEPTION;

   SYSTEM_GID_SAPD                 CONSTANT CHAR(2):= '00';
   SYSTEM_GID_SZD                  CONSTANT CHAR(2):= 'ZD';
   SYSTEM_GID_UROGO                CONSTANT CHAR(2):= 'UR';

   MIN_DUMMY_DATE                  CONSTANT DATE:= TO_DATE('01.01.1900', 'dd.mm.yyyy');
   MAX_DUMMY_DATE                  CONSTANT DATE:= TO_DATE('01.01.2200', 'dd.mm.yyyy');
   NO_NAME_DATA                    CONSTANT VARCHAR2(30) :='[отсутствует]';

   EXPHIST_STATUS_INIT             CONSTANT NUMBER:= 11901;   -- Initialized
   EXPHIST_STATUS_INPROG           CONSTANT NUMBER:= 11902;   -- InProgress
   EXPHIST_STATUS_SENT             CONSTANT NUMBER:= 11903;   -- Sent
   EXPHIST_STATUS_SUCCESS          CONSTANT NUMBER:= 11904;   -- Success
   EXPHIST_STATUS_FAILED           CONSTANT NUMBER:= 11905;   -- Failed

   ERR_LOCK_DEADLOCK               CONSTANT PLS_INTEGER:= -20001;
   MSG_LOCK_DEADLOCK               CONSTANT VARCHAR2(500):= 'Обнаружена взаимная блокировка!';
   ERR_LOCK_OBTAINED               CONSTANT PLS_INTEGER:= -20002;
   MSG_LOCK_OBTAINED               CONSTANT VARCHAR2(500):= 'Блокировка уже существует';
   ERR_LOCK_REQUEST_FAILED         CONSTANT PLS_INTEGER:= -20003;
   MSG_LOCK_REQUEST_FAILED         CONSTANT VARCHAR2(500):= 'Сбой при запросе блокировки';
   ERR_LOCK_RELEASE_FAILED         CONSTANT PLS_INTEGER:= -20004;
   MSG_LOCK_RELEASE_FAILED         CONSTANT VARCHAR2(500):= 'Сбой при освобождении блокировки';
   ERR_INVALID_INPUT_PARAMS        CONSTANT PLS_INTEGER:= -20011;
   MSG_INVALID_INPUT_PARAMS        CONSTANT VARCHAR2(500):= 'Входные параметры некорректны';
   ERR_NO_REQUIRED_INPUT_PARAMS    CONSTANT PLS_INTEGER:= -20012;
   MSG_NO_REQUIRED_INPUT_PARAMS    CONSTANT VARCHAR2(500):= 'Входные параметры не заполнены';
   ERR_JOB_ALREADY_RUNNING         CONSTANT PLS_INTEGER:= -20013;
   MSG_JOB_ALREADY_RUNNING         CONSTANT VARCHAR2(500):= 'Задача уже существует и выполняется';
   ERR_FIELD_UPDATE_DENIED         CONSTANT PLS_INTEGER:= -20014;
   MSG_FIELD_UPDATE_DENIED         CONSTANT VARCHAR2(500):= 'Изменение значения поля запрещено';
   ERR_INVALID_INSTANCE            CONSTANT PLS_INTEGER:= -20015;
   MSG_INVALID_INSTANCE            CONSTANT VARCHAR2(500):= 'Операция недопустима для экземляра приложения';

   ERR_MISSING_RECORD              CONSTANT PLS_INTEGER:= -20101;
   MSG_MISSING_RECORD              CONSTANT VARCHAR2(500):= 'Запись отсутствует в таблице';
   ERR_LOG_RECORD_FOUND            CONSTANT PLS_INTEGER:= -20102;
   MSG_LOG_RECORD_FOUND            CONSTANT VARCHAR2(500):= 'Обновление запрещено: имеются связанные записи журнала';
   ERR_MANY_RECORDS_FOUND          CONSTANT PLS_INTEGER:= -20103;
   MSG_MANY_RECORDS_FOUND          CONSTANT VARCHAR2(500):= 'Найдено больше требуемого количества записей';

   ERR_NO_CHANGED_ATTRIBUTES       CONSTANT PLS_INTEGER:= -20201;
   MSG_NO_CHANGED_ATTRIBUTES       CONSTANT VARCHAR2(500):= 'Аттрибуты объектов коррекции не изменились';
   ERR_OUTPUT_OBJECTS              CONSTANT PLS_INTEGER:= -20202;
   MSG_OUTPUT_OBJECTS              CONSTANT VARCHAR2(500):= 'Коррекция недопустима: объекты являются выходными в делах';
   ERR_DIFFERENT_OBJECTS           CONSTANT PLS_INTEGER:= -20203;
   MSG_DIFFERENT_OBJECTS           CONSTANT VARCHAR2(500):= 'Коррекция недопустима: аттрибуты принадлежат разным объектам';
   ERR_DIFFERENT_DOC_TYPES         CONSTANT PLS_INTEGER:= -20204;
   MSG_DIFFERENT_DOC_TYPES         CONSTANT VARCHAR2(500):= 'Коррекция недопустима: документы различных типов';
   ERR_EXISTING_INN                CONSTANT PLS_INTEGER:= -20205;
   MSG_EXISTING_INN                CONSTANT VARCHAR2(500):= 'Коррекция недопустима: ИНН используется другим юридическим лицом';

   ERR_CNCL_EXPORTED_CASE          CONSTANT PLS_INTEGER:= -20251;
   MSG_CNCL_EXPORTED_CASE          CONSTANT VARCHAR2(500):= 'Невозможно отменить дело, выгруженное во внешнюю систему';
   ERR_CNCL_INVALID_CASE_TYPE      CONSTANT PLS_INTEGER:= -20252;
   MSG_CNCL_INVALID_CASE_TYPE      CONSTANT VARCHAR2(500):= 'Отмена данного типа дела невозможна';
   ERR_CNCL_INVALID_STATUS         CONSTANT PLS_INTEGER:= -20253;
   MSG_CNCL_INVALID_STATUS         CONSTANT VARCHAR2(500):= 'Невозможно отменить дело при текущем статусе';
   ERR_CNCL_INVALID_OPERATION      CONSTANT PLS_INTEGER:= -20254;
   MSG_CNCL_INVALID_OPERATION      CONSTANT VARCHAR2(500):= 'Проведенные над делом операции запрещают его отмену';
   ERR_CNCL_PAYMENT_EXISTS         CONSTANT PLS_INTEGER:= -20255;
   MSG_CNCL_PAYMENT_EXISTS         CONSTANT VARCHAR2(500):= 'Невозможно отменить дело. Со связанного платежного документа выполнены списания';
   ERR_CNCL_EXPORTED_LINK_CASE     CONSTANT PLS_INTEGER:= -20256;
   MSG_CNCL_EXPORTED_LINK_CASE     CONSTANT VARCHAR2(500):= 'Невозможно отменить дело. Связанное дело выгружено во внешнюю систему';
   ERR_CNCL_INVALID_LINK_STATUS    CONSTANT PLS_INTEGER:= -20257;
   MSG_CNCL_INVALID_LINK_STATUS    CONSTANT VARCHAR2(500):= 'Невозможно отменить дело. Связанное дело имеет статус, запрещающий отмену';
   ERR_CNCL_INVALID_WORKFLOW       CONSTANT PLS_INTEGER:= -20258;
   MSG_CNCL_INVALID_WORKFLOW       CONSTANT VARCHAR2(500):= 'Невозможно отменить дело. Сначала необходимо отменить связанное дело';
   ERR_CNCL_CHARGED_PAYMENT        CONSTANT PLS_INTEGER:= -20259;
   MSG_CNCL_CHARGED_PAYMENT        CONSTANT VARCHAR2(500):= 'Невозможно отменить дело. Имеется подтверждение оплаты из ФК';

   ERR_MANY_OUTPUT_ROLES           CONSTANT PLS_INTEGER:= -20301;
   MSG_MANY_OUTPUT_ROLES           CONSTANT VARCHAR2(500):= 'Допустим только один объект с выходной ролью';
   ERR_OUTPUT_DOC_DELETE           CONSTANT PLS_INTEGER:= -20302;
   MSG_OUTPUT_DOC_DELETE           CONSTANT VARCHAR2(500):= 'Попытка удалить выходной документ';
   ERR_CHECK_RUS_NAMES_1           CONSTANT PLS_INTEGER:= -20303;
   MSG_CHECK_RUS_NAMES_1           CONSTANT VARCHAR2(500):= 'Имя и фамилия (кириллица) не могут быть пустыми';
   ERR_CHECK_RUS_NAMES_2           CONSTANT PLS_INTEGER:= -20304;
   MSG_CHECK_RUS_NAMES_2           CONSTANT VARCHAR2(500):= 'Фамилия (кириллица) содержит недопустимые символы';
   ERR_CHECK_RUS_NAMES_3           CONSTANT PLS_INTEGER:= -20305;
   MSG_CHECK_RUS_NAMES_3           CONSTANT VARCHAR2(500):= 'Имя (кириллица) содержит недопустимые символы';
   ERR_CHECK_RUS_NAMES_4           CONSTANT PLS_INTEGER:= -20306;
   MSG_CHECK_RUS_NAMES_4           CONSTANT VARCHAR2(500):= 'Отчество (кириллица) содержит недопустимые символы';
   ERR_CHECK_LAT_NAMES_1           CONSTANT PLS_INTEGER:= -20307;
   MSG_CHECK_LAT_NAMES_1           CONSTANT VARCHAR2(500):= 'Фамилия (транслит) содержит недопустимые символы';
   ERR_CHECK_LAT_NAMES_2           CONSTANT PLS_INTEGER:= -20308;
   MSG_CHECK_LAT_NAMES_2           CONSTANT VARCHAR2(500):= 'Имя (транслит) содержит недопустимые символы';
   ERR_CHECK_LAT_NAMES_3           CONSTANT PLS_INTEGER:= -20309;
   MSG_CHECK_LAT_NAMES_3           CONSTANT VARCHAR2(500):= 'Отчество (транслит) содержит недопустимые символы';
   ERR_CHECK_HIERARCHY             CONSTANT PLS_INTEGER:= -20310;
   MSG_CHECK_HIERARCHY             CONSTANT VARCHAR2(500):= 'Неверный уровень иерархии';
   ERR_CHECK_ORG_TYPE              CONSTANT PLS_INTEGER:= -20311;
   MSG_CHECK_ORG_TYPE              CONSTANT VARCHAR2(500):= 'Неверный тип организации';
   ERR_DEFECTIVE_PRINT_LIMIT       CONSTANT PLS_INTEGER:= -20312;
   MSG_DEFECTIVE_PRINT_LIMIT       CONSTANT VARCHAR2(500):= 'Исчерпан лимит допустимых ошибок при печати';
   ERR_MANY_INPUT_ROLES            CONSTANT PLS_INTEGER:= -20313;
   MSG_MANY_INPUT_ROLES            CONSTANT VARCHAR2(500):= 'Допустим только один объект с входной ролью';

   ERR_INSERT_EXISTING_BLANK       CONSTANT PLS_INTEGER:=- 20404;
   MSG_INSERT_EXISTING_BLANK       CONSTANT VARCHAR2(500):= 'Бланк указанных типа, серии и номера уже существует';
   ERR_UPDATE_MISSING_BLANK        CONSTANT PLS_INTEGER:= -20407;
   MSG_UPDATE_MISSING_BLANK        CONSTANT VARCHAR2(500):= 'Попытка обновить статус несуществующих бланков';
   ERR_INVALID_RECEIPT_DATE        CONSTANT PLS_INTEGER:= -20408;
   MSG_INVALID_RECEIPT_DATE        CONSTANT VARCHAR2(500):= 'Неверная дата документа-основания операции';
   ERR_NOT_ALL_BLANKS_AVAILABLE    CONSTANT PLS_INTEGER:= -20409;
   MSG_NOT_ALL_BLANKS_AVAILABLE    CONSTANT VARCHAR2(500):= 'Не все бланки находятся в распоряжении подразделения-отправителя';
   ERR_BLANK_ALREADY_USED          CONSTANT PLS_INTEGER:= -20410;
   MSG_BLANK_ALREADY_USED          CONSTANT VARCHAR2(500):= 'В диапазоне есть использованные бланки';
   ERR_NOT_IN_WAREHOUSE            CONSTANT PLS_INTEGER:= -20411;
   MSG_NOT_IN_WAREHOUSE            CONSTANT VARCHAR2(500):= 'Не все бланки находятся на складе';
   ERR_NOT_IN_WAREHOUSE_OR_IMPORT  CONSTANT PLS_INTEGER:= -20412;
   MSG_NOT_IN_WAREHOUSE_OR_IMPORT  CONSTANT VARCHAR2(500):= 'Не все бланки находятся на складе или в подразделении';
   ERR_NOT_AT_SENDER               CONSTANT PLS_INTEGER:= -20413;
   MSG_NOT_AT_SENDER               CONSTANT VARCHAR2(500):= 'Один или несколько указанных бланков не находятся в организации-отправителе';

   ERR_TOO_MANY_ACTUAL_ADDRESSES   CONSTANT PLS_INTEGER:= -20501;
   MSG_TOO_MANY_ACTUAL_ADDRESSES   CONSTANT VARCHAR2(500):= 'Найдено более одного актуального адреса';

   PROCEDURE ERROR_PROCESSING (ERR_PLACE   IN VARCHAR2,
                               ERR_PARAM   IN VARCHAR2,
                               ERR_MESSAGE IN VARCHAR2);

END TOOLS;
/
CREATE OR REPLACE PACKAGE BODY TEST.TOOLS AS
   PROCEDURE ERROR_PROCESSING (ERR_PLACE   IN VARCHAR2,
                               ERR_PARAM   IN VARCHAR2,
                               ERR_MESSAGE IN VARCHAR2) AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO error_log (erl_datetime,
                             erl_place,
                             erl_parameter,
                             erl_message)
      VALUES (SYSTIMESTAMP,
              SUBSTRB(err_place, 1, 100),
              SUBSTRB(err_param, 1, 250),
              SUBSTRB(err_message, 1, 250));
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
   END error_processing;

END TOOLS;
/

--Create package TEST.CORE_UTILS (выполнять в схеме TEST)

CREATE OR REPLACE PACKAGE TEST.CORE_UTILS AS
--------------------------------------------------------------------------------
   FUNCTION GET_CURR_ORGSTATUS_BY_CASE (ORG_CASE_ID IN NUMBER) RETURN NUMBER;
   FUNCTION GET_CURR_PERSONSTATUS_BY_CASE (PERSON_CASE_ID IN NUMBER) RETURN NUMBER;
END CORE_UTILS;
/

CREATE OR REPLACE PACKAGE BODY TEST.CORE_UTILS AS
   EXIT_EXCEPTION    EXCEPTION;

   FUNCTION GET_CURR_ORGSTATUS_BY_CASE (ORG_CASE_ID IN NUMBER) RETURN NUMBER AS
   -- Возвращает текущий статус юридического лица по данному делу
      res        NUMBER;
   BEGIN
      SELECT v.status_id
        INTO res
        FROM (SELECT s.status_id
                FROM core_org_statestatus s,
                     core_org_operation t,
                     core_org_case p
               WHERE p.id = ORG_CASE_ID
                 AND p.organization_state_id = s.organization_state_id
                 AND p.id = t.case_id
                 AND t.id = s.operation_id
               ORDER BY s.operation_id DESC) v
       WHERE ROWNUM < 2;

      RETURN res;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;
      WHEN OTHERS THEN
         tools.error_processing('CORE_UTILS.GET_CURR_ORGSTATUS_BY_CASE',
                                'ORG_CASE_ID=' || TO_CHAR(ORG_CASE_ID),
                                SQLERRM);
         RAISE;
   END get_curr_orgstatus_by_case;


   FUNCTION GET_CURR_PERSONSTATUS_BY_CASE (PERSON_CASE_ID IN NUMBER) RETURN NUMBER AS
   -- Возвращает текущий статус физического лица по данному делу
      res        NUMBER;
   BEGIN
      SELECT v.status_id
        INTO res
        FROM (SELECT s.status_id
                FROM core_personstatestatus s,
                     core_operation t,
                     core_person_case p
               WHERE p.id = PERSON_CASE_ID
                 AND p.person_state_id = s.person_state_id
                 AND p.id = t.case_id
                 AND t.id = s.operation_id
               ORDER BY s.operation_id DESC) v
       WHERE ROWNUM < 2;

      RETURN res;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;
      WHEN OTHERS THEN
         tools.error_processing('CORE_UTILS.GET_CURR_PERSONSTATUS_BY_CASE',
                                'PERSON_CASE_ID=' || TO_CHAR(PERSON_CASE_ID),
                                SQLERRM);
         RAISE;
   END get_curr_personstatus_by_case;
END CORE_UTILS;
/


