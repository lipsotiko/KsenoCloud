CREATE PROCEDURE [dbo].[Sp_add_client] @userid              VARCHAR(12), 
                                       @password            VARCHAR(12), 
                                       @email               VARCHAR(100), 
                                       @first_name          VARCHAR(50), 
                                       @last_name           VARCHAR(50), 
                                       @street              VARCHAR(100), 
                                       @city                VARCHAR(50), 
                                       @state               CHAR(2), 
                                       @zipcode             INT, 
                                       @phone               VARCHAR(50), 
                                       @plan_id             INT, 
                                       @company_name        VARCHAR(50), 
                                       @card_holder_name    VARCHAR(50), 
                                       @card_number         VARCHAR(17), 
                                       @card_security_code  VARCHAR(4), 
                                       @card_expiration_yr  INT, 
                                       @card_expiration_mth INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: When a new customer wants to register themselves 
    as a subscriber to KsenoCloud, this SP can be used. 
     
    How to: 
        exec [sp_add_client] 
        @userid = 'eponere1', 
        @password = 'test1234', 
        @email = 'lipsotiko@gmail.com', 
        @first_name    = 'Evangelo', 
        @last_name    = 'Poneres', 
        @street = '2307 Oakmont Rd.', 
        @city = 'Fallston', 
        @state = 'MD', 
        @zipcode = 21047, 
        @phone = '4433019719', 
        @plan_id = 1, 
        @company_name = 'Vangos Inns America', 
        @card_holder_name = 'Evangelos Poneres', 
        @card_number = '12345678912345678', 
        @card_security_code = 'a123', 
        @card_expiration_yr = 2016, 
        @card_expiration_mth = 5 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      --create a variable to catch the address id when the address table is updated 
      DECLARE @address_id INT 
      DECLARE @address_out_tbl TABLE 
        ( 
           id INT 
        ) 

      --insert the clients address into the address table 
      INSERT INTO t_address 
                  (street, 
                   city, 
                   state, 
                   zipcode) 
      output      inserted.address_id 
      INTO @address_out_tbl(id) 
      VALUES      (@street, 
                   @city, 
                   @state, 
                   @zipcode) 

      --assign the address id to the @address_id variable 
      SET @address_id = (SELECT id 
                         FROM   @address_out_tbl) 

  /*********************************/ 
      --create a variable to catch the client id when the client table is updated 
      DECLARE @client_id INT 
      DECLARE @client_id_out_tbl TABLE 
        ( 
           id INT 
        ) 

      --add the clients information into the client table 
      INSERT INTO t_client 
                  (plan_id, 
                   company_name, 
                   address_id, 
                   is_active_flag, 
                   phone, 
                   date_joined) 
      output      inserted.client_id 
      INTO @client_id_out_tbl(id) 
      VALUES     (@plan_id, 
                  @company_name, 
                  @address_id, 
                  1, 
                  @phone, 
                  Getdate()) 

      --assign the clients id to the @client_id variable 
      SET @client_id = (SELECT id 
                        FROM   @client_id_out_tbl) 

  /*********************************/ 
      --create a user account for the client 
      INSERT INTO t_user 
                  ([user_id], 
                   client_id, 
                   password, 
                   email, 
                   first_name, 
                   last_name, 
                   role_id, 
                   is_active_flag, 
                   hotel_id) 
      VALUES      (@userid, 
                   @client_id, 
                   @password, 
                   @email, 
                   @first_name, 
                   @last_name, 
                   1, 
                   1, 
                   NULL) 

  /*********************************/ 
      --create a variable to catch the clients card id when the creditcard table is updated 
      DECLARE @client_card_id INT 
      DECLARE @client_card_out_tbl TABLE 
        ( 
           id INT 
        ) 

      --add the clients initial payment method 
      INSERT INTO t_creditcard 
                  (card_holder_name, 
                   number, 
                   security_code, 
                   expiration_yr, 
                   expiration_mth) 
      output      inserted.card_id 
      INTO @client_card_out_tbl(id) 
      VALUES      (@card_holder_name, 
                   @card_number, 
                   @card_security_code, 
                   @card_expiration_yr, 
                   @card_expiration_mth) 

      --assign the card id to a variable 
      SET @client_card_id = (SELECT id 
                             FROM   @client_card_out_tbl) 

      /*********************************/ 
      INSERT INTO t_payment 
                  (client_id, 
                   card_id, 
                   default_pmt) 
      VALUES      (@client_id, 
                   @client_card_id, 
                   1) 

      COMMIT TRANSACTION 

      SELECT 0         AS errNum, 
             'success' AS status 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      IF Error_number() = 2627 
        BEGIN 
            SELECT 1 
                   AS errNum, 
        'Error: The username supplied is already in use, please try again.' 
        AS 
        status 
        END 
      ELSE 
        BEGIN 
            SELECT 1               AS errNum, 
                   Error_message() AS status 
        END 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_add_comment] @user_id  VARCHAR(12), 
                                        @guest_id INT, 
                                        @comment  VARCHAR(1000), 
                                        @type     VARCHAR(50) 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: To be used if a guest would like to leave a comment during / after their stay. 
     
    How to: 
        exec [sp_add_comment] 
        @user_id = 'eponere1', 
        @guest_id = 2, 
        @comment = 'This hotel was bad...', 
        @type = 'NEG' 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      --Does the user have the authority to add comments, and for the specified guest? 
      --If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
            'CLIENT', 'MANAGER', 'FRONT DESK CLERK' ) 
         AND (SELECT client_id 
              FROM   t_user 
              WHERE  Lower(user_id) = Lower(@user_id)) = (SELECT client_id 
                                                          FROM   t_hotel 
                                                          WHERE 
             hotel_id = (SELECT hotel_id 
                         FROM   t_guest 
                         WHERE  guest_id 
                        = @guest_id)) 
        BEGIN 
            INSERT INTO t_guest_comments 
                        (guest_id, 
                         comment, 
                         type) 
            VALUES     (@guest_id, 
                        @comment, 
                        @type) 

            COMMIT TRANSACTION 

            SELECT 0         AS errorNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR( 
            'Error: You are not authorized to add comments for this guest.', 
            16 
            ,1) 
        END 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errorNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_add_hotel] @user_id                  VARCHAR(12), 
                                      @hotel_name               VARCHAR(50), 
                                      @checkin_deadline         TIME, 
                                      @checkout_deadline        TIME, 
                                      @additional_occupant_cost NUMERIC(5, 2), 
                                      @late_checkout_cost       NUMERIC(5, 2), 
                                      @street                   VARCHAR(100), 
                                      @city                     VARCHAR(50), 
                                      @state                    CHAR(2), 
                                      @zipcode                  INT, 
                                      @is_active                BIT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP can be used when a Client wants to add hotels to their account. 
     
    How to: 
        exec [sp_add_hotel] 
        @user_id = 'eponere1', 
        @hotel_name = 'Vangos Inn Aberdeen', 
        @checkin_deadline = '16:00', 
        @checkout_deadline = '12:00', 
        @additional_occupant_cost = '20.00', 
        @late_checkout_cost = '45.00', 
        @street = '123 Van Way', 
        @city = 'Aberdeen', 
        @state = 'MD', 
        @zipcode = 21001 
    **********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /*********************************/ 
      --First see if the user is allowed to add hotels, 
      --and if so, how many they are allowed to add based on the service plan 
      DECLARE @client_id INT 
      DECLARE @continue BIT 

      --Is the user a client? If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
        BEGIN 
        /********************************/ 
            --add the hotels address to the address table 
            DECLARE @address_id INT 
            DECLARE @address_out_tbl TABLE 
              ( 
                 id INT 
              ) 

            INSERT INTO t_address 
                        (street, 
                         city, 
                         state, 
                         zipcode) 
            output      inserted.address_id 
            INTO @address_out_tbl(id) 
            VALUES      (@street, 
                         @city, 
                         @state, 
                         @zipcode) 

            SET @address_id = (SELECT id 
                               FROM   @address_out_tbl) 
            /*********************************/ 
            SET @client_id = (SELECT client_id 
                              FROM   t_user 
                              WHERE  Lower(user_id) = Lower(@user_id)) 

            --add the clients hotel to the hotel table 
            INSERT INTO t_hotel 
                        (client_id, 
                         name, 
                         address_id, 
                         checkin_deadline, 
                         checkout_deadline, 
                         additional_occupant_cost, 
                         late_checkout_cost, 
                         is_active) 
            VALUES      (@client_id, 
                         @hotel_name, 
                         @address_id, 
                         @checkin_deadline, 
                         @checkout_deadline, 
                         @additional_occupant_cost, 
                         @late_checkout_cost, 
                         @is_active) 

            --Make sure the user did not exceed their maximum number of hotel 
            EXEC Sp_chk_hotels 
              @client_id, 
              @continue output 

            IF @continue = 0 
              BEGIN 
                  RAISERROR( 
        'Error: You have reached your maximum number of active hotels.', 
        16 
        ,5) 
              END 
            ELSE 
              BEGIN 
                  COMMIT TRANSACTION 

                  SELECT 0         AS errNum, 
                         'success' AS status 
              END 
        /*********************************/ 
        END 
      ELSE 
        BEGIN 
            RAISERROR ('Error: You are not authorized to add hotels.',16,5); 
        END 
  /*********************************/ 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_add_payment] @user_id             VARCHAR(12), 
                                   @card_holder_name    VARCHAR(50), 
                                   @card_number         VARCHAR(17), 
                                   @card_security_code  VARCHAR(4), 
                                   @card_expiration_mth INT, 
                                   @card_expiration_yr  INT 
AS 
    /*********************************** 
    Author: Evangelos Poneres 
    Notes: To be used for adding a payment method to a client's account 
    ***********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
        BEGIN 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 
            DECLARE @card_id INT 
            DECLARE @card_out_tbl TABLE 
              ( 
                 id INT 
              ) 

            INSERT INTO t_creditcard 
                        (card_holder_name, 
                         number, 
                         security_code, 
                         expiration_mth, 
                         expiration_yr) 
            output      inserted.card_id 
            INTO @card_out_tbl(id) 
            VALUES      (@card_holder_name, 
                         @card_number, 
                         @card_security_code, 
                         @card_expiration_mth, 
                         @card_expiration_yr) 

            SET @card_id = (SELECT id 
                            FROM   @card_out_tbl) 

            INSERT INTO t_payment 
                        (client_id, 
                         card_id, 
                         default_pmt) 
            VALUES     (@client_id, 
                        @card_id, 
                        0) 

            COMMIT TRANSACTION 

            SELECT 1         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            SELECT 0               AS errNum, 
                   Error_message() AS status 

            RAISERROR( 
  'Error: You are not authorized to add payment methods to this account' 
  ,16, 
  5) 
        END 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_add_rate] @user_id     VARCHAR(12), 
                                     @description VARCHAR(50), 
                                     @rate        VARCHAR(50) 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: When a new Client wants to add a rate 'bucket' for group their hotel rooms, this SP can be used. 
     
    How to: 
        exec [sp_add_rate] @user_id = 'eponere1', @description = 'Ocean Front 1st Floor', @rate = 249.99 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /*********************************/ 
      --First see if the user is allowed to add rates 
      --Is the user a client? If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
        BEGIN 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 

            INSERT INTO t_hotel_room_rate 
                        (client_id, 
                         description, 
                         rate) 
            VALUES      (@client_id, 
                         @description, 
                         @rate) 

            --if the insert was successful, then commit 
            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_add_room] @user_id       VARCHAR(12), 
                                     @hotel_id      INT, 
                                     @room_name     VARCHAR(50), 
                                     @description   VARCHAR(50), 
                                     @phone         VARCHAR(50), 
                                     @max_occupants INT, 
                                     @rate_id       INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: To be used when a Client wants to add a room to one of their hotels. 
     
    How to: 
        exec [sp_add_room] 
        @user_id = 'eponere1', 
        @hotel_id = 1, 
        @room_name = 'S243', 
        @description = '2 x Queen, 1 x Couch', 
        @phone = '4435874157', 
        @max_occupants = 3, 
        @rate_id = 0 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /*********************************/ 
      --First see if the user is allowed to add rooms 
      --Is the user a client and does the rate belong to them? If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
         AND (SELECT client_id 
              FROM   t_hotel_room_rate 
              WHERE  rate_id = @rate_id) = (SELECT client_id 
                                            FROM   t_user 
                                            WHERE  Lower(user_id) = 
                                                   Lower(@user_id)) 
        BEGIN 
            INSERT INTO t_room 
                        (hotel_id, 
                         room_name, 
                         description, 
                         rate_id, 
                         phone, 
                         max_occupants, 
                         status) 
            VALUES      (@hotel_id, 
                         @room_name, 
                         @description, 
                         @rate_id, 
                         @phone, 
                         @max_occupants, 
                         'VACANT') 

            --if the insert was successful, then commit 
            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR ( 
'Error: You are either not authorized to add a room to the requested hotel, the rate does not belong to your account, or a duplicate room number exists.' 
,16,1) 
END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_add_user] @user_id     VARCHAR(12), 
                                     @new_user_id VARCHAR(12), 
                                     @password    VARCHAR(12), 
                                     @email       VARCHAR(100), 
                                     @first_name  VARCHAR (50), 
                                     @last_name   VARCHAR (50), 
                                     @role_id     INT, 
                                     @hotel_id    INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: When a Client wants to add a user to their account, this SP can assist 
     
    How to: 
      exec sp_add_user 
      @user_id = 'eponere1', 
      @new_user_id = 'dgreen1', 
      @password = 'test4321', 
      @email = 'dgreen1@vanInt.com', 
      @first_name = 'Don', 
      @last_name = 'Green', 
      @role_id = 2, 
      @hotel_id = 1 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /*********************************/ 
      --First see if the user is allowed to add users 
      --Is the user a client and is the specified hotel part of their account? If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
         AND @hotel_id IN (SELECT hotel_id 
                           FROM   t_hotel 
                           WHERE  client_id = (SELECT client_id 
                                               FROM   t_user 
                                               WHERE  Lower(user_id) = Lower( 
                                                      @user_id) 
                                              )) 
        BEGIN 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 

            INSERT INTO t_user 
                        (user_id, 
                         client_id, 
                         password, 
                         email, 
                         first_name, 
                         last_name, 
                         role_id, 
                         is_active_flag, 
                         hotel_id) 
            VALUES      (@new_user_id, 
                         @client_id, 
                         @password, 
                         @email, 
                         @first_name, 
                         @last_name, 
                         @role_id, 
                         1, 
                         @hotel_id) 

            --if the insert was successful, then commit 
            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR( 
'Error: You are either not authorized to add users, or to add users to the specified hotel.' 
,16,3) 
END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_add_wake_up_call] @user_id    VARCHAR(12), 
                                             @guest_id   INT, 
                                             @alarm_time DATETIME 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP will allow a user to add a wakeup call for a particular guest. 
     
    How to: 
      exec sp_add_wake_up_call 
      @user_id = 'eponere1', 
      @guest_id = 6, 
      @alarm_time = '2013-11-08 18:05:24.880' 
    **********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      --First, lets check for proper authorization 
      --Is the user allowed to add wake-up calls? And is the guest staying at the users hotel. 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
            'CLIENT', 'MANAGER', 'FRONT DESK CLERK' ) 
         AND (SELECT client_id 
              FROM   t_user 
              WHERE  Lower(user_id) = Lower(@user_id)) = (SELECT client_id 
                                                          FROM   t_hotel 
                                                          WHERE 
             hotel_id = (SELECT hotel_id 
                         FROM   t_guest 
                         WHERE  guest_id 
                        = @guest_id)) 
        BEGIN 
            --Also, make sure the alarm_time is not less than today's date 
            IF @alarm_time < Getdate() 
              BEGIN 
                  RAISERROR('Error: The time supplied is not valid.',16,2) 
              END 

            INSERT INTO t_wakeup 
                        (guest_id, 
                         alarm_time) 
            VALUES      (@guest_id, 
                         @alarm_time) 

            COMMIT TRANSACTION 

            SELECT 0         AS errorNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR( 
'Error: You are either not authorized to add wakeup calls, or add them for the requested guest.' 
,16,1) 
END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errorNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_auto_generate_client_invoice] 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP will be used to generate invoices for each client based on the service plan they chose. 
    *********************************/ 
    DECLARE @client_id INT 
    DECLARE @room_cost NUMERIC(12, 2) 
    DECLARE @tran_cost NUMERIC(12, 2) 
    DECLARE @mly_cost NUMERIC(12, 2) 
    DECLARE @num_rooms INT 
    DECLARE @card_id INT 
    DECLARE @posting_date DATETIME = Getdate() 
    DECLARE @due_date DATETIME = Dateadd(wk, 2, Getdate()) 
    --Give the customer 2 weeks to pay their bill 
    DECLARE @start_date DATETIME 
    DECLARE @end_date DATETIME 
    DECLARE @check_ins INT 
    DECLARE @check_outs INT 
    DECLARE @total_cost NUMERIC(12, 2) 
    DECLARE @fees NUMERIC(12, 2) 
    --Curse through each client and generate their invoice 
    DECLARE cur CURSOR FOR 
      SELECT c.client_id, 
             s.room_cost, 
             s.transaction_cost, 
             s.monthly_cost 
      FROM   t_client c 
             INNER JOIN t_service s 
                     ON c.plan_id = s.plan_id 
                        AND c.is_active_flag = 1 

    OPEN cur 

    FETCH next FROM cur INTO @client_id, @room_cost, @tran_cost, @mly_cost 

    WHILE @@FETCH_STATUS = 0 
      BEGIN 
          BEGIN try 
              BEGIN TRANSACTION 

              --first make sure this client has kept up with their payments 
              --if they have missed 3 payments, deactivate their account 
              IF (SELECT Count(*) 
                  FROM   t_invoice 
                  WHERE  client_id = @client_id 
                         AND paid_flag = 0) = 3 
                BEGIN 
                    PRINT( 
'Error: This client missed 3 payments and their account has been deactivated: ' 
+ CONVERT(VARCHAR(50), @client_id) ) 

    UPDATE t_client 
    SET    is_active_flag = 0 
    WHERE  client_id = @client_id 
END 

    --if the client missed less than 3 payments, charge their account additional fees 
    IF (SELECT Count(*) 
        FROM   t_invoice 
        WHERE  client_id = @client_id 
               AND paid_flag = 0) BETWEEN 1 AND 3 
      BEGIN 
          SET @fees = 24.99 
      END 
    ELSE 
      BEGIN 
          SET @fees = 0 
      END 

    --if this this the clients first invoice, use the date they joined as the service start date. 
    IF NOT EXISTS (SELECT TOP 1 * 
                   FROM   t_invoice 
                   WHERE  client_id = 1) 
      BEGIN 
          SET @start_date = (SELECT date_joined 
                             FROM   t_client 
                             WHERE  client_id = @client_id) 
      END 
    --otherwise find the end_date of their previous invoice, if this SP was run 
    --for a single client in order for them to change their plan, this logic should "pro-rate" their invoice. 
    ELSE 
      BEGIN 
          SELECT TOP 1 @start_date = service_end_date 
          FROM   t_invoice 
          WHERE  client_id = @client_id 
          ORDER  BY invoice_id DESC 
      END 

    --did the client terminate their service? 
    IF (SELECT date_terminated 
        FROM   t_client 
        WHERE  client_id = @client_id) IS NOT NULL 
       AND (SELECT date_terminated 
            FROM   t_client 
            WHERE  client_id = @client_id) > @start_date 
      --if so, and the termination date is after the derived start date...use their termination date as the end date. 
      BEGIN            SET @end_date = (SELECT date_terminated                             FROM   t_client                             WHERE  client_id = @client_id)        END      ELSE        BEGIN            SET @end_date = @posting_date        END       --Figure out the total cost for all the rooms the client has      SELECT @room_cost = @room_cost * Count(*),             @num_rooms = Count(*)      FROM   t_hotel h             INNER JOIN t_room r                     ON h.hotel_id = r.hotel_id      WHERE  h.client_id = @client_id       --Figure out the total cost for all transactions (Check-ins)      SELECT @check_ins = Count(*)      FROM   t_client c             INNER JOIN t_hotel h                     ON c.client_id = h.client_id             INNER JOIN t_guest g                     ON h.hotel_id = g.hotel_id      WHERE  g.checkin_time IS NOT NULL             AND g.checkin_time BETWEEN @start_date AND @end_date             AND c.client_id = @client_id       --Figure out the total cost for all transactions (Check-outs)      SELECT @check_outs = Count(*)      FROM   t_client c             INNER JOIN t_hotel h                     ON c.client_id = h.client_id             INNER JOIN t_guest g                     ON h.hotel_id = g.hotel_id      WHERE  g.checkout_time IS NOT NULL             AND g.checkout_time BETWEEN @start_date AND @end_date             AND c.client_id = @client_id       --incase there were not check-ins or checkouts at any of the clients hotels      IF ( @check_ins = 0           AND @check_outs = 0 )        BEGIN            SET @tran_cost = 0        END      ELSE        BEGIN            SET @tran_cost = ( @tran_cost * @check_ins ) +                             ( @tran_cost * @check_outs )        END       SET @total_cost = @room_cost + @tran_cost + @mly_cost + @fees       --which credit card will be used? 
    SELECT @card_id = cc.card_id 
    FROM   t_client c 
           INNER JOIN t_payment p 
                   ON c.client_id = p.client_id 
           INNER JOIN t_creditcard cc 
                   ON cc.card_id = p.card_id 
    WHERE  p.default_pmt = 1 
           AND c.client_id = @client_id 

    /*************************************************************** 
    This section can be used to process a credit card transaction... 
    we will assume it is successful. 
    ****************************************************************/ 
    INSERT INTO t_invoice 
                (client_id, 
                 date, 
                 service_start_date, 
                 service_end_date, 
                 check_ins, 
                 check_outs, 
                 card_id, 
                 total_cost, 
                 paid_flag, 
                 payment_due_date, 
                 num_rooms, 
                 fees) 
    VALUES     (@client_id, 
                @posting_date, 
                @start_date, 
                @end_date, 
                @check_ins, 
                @check_outs, 
                @card_id, 
                @total_cost, 
                0, 
                @due_date, 
                @num_rooms, 
                @fees) 

    SET @check_ins = NULL 
    SET @check_outs = NULL 
    SET @start_date = NULL 
    SET @end_date = NULL 
    SET @card_id = NULL 
    SET @total_cost = NULL 
    SET @fees = NULL 
    SET @num_rooms = NULL 

    COMMIT TRANSACTION 
END try 

    BEGIN catch 
        ROLLBACK TRANSACTION 

        SELECT @client_id      AS client_id, 
               Error_message() AS error 
    END catch 

    FETCH next FROM cur INTO @client_id, @room_cost, @tran_cost, @mly_cost 
END 

    CLOSE cur 
    DEALLOCATE cur 

go  

CREATE PROCEDURE [dbo].[Sp_auto_generate_client_invoice_srvc_change] 
	@client_id INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP will be used to generate invoices for a client that decides to change their service plan. 
    --see [sp_change_client_service] 
    *********************************/ 
    DECLARE @room_cost NUMERIC(12, 2) 
    DECLARE @tran_cost NUMERIC(12, 2) 
    DECLARE @mly_cost NUMERIC(12, 2) 
    DECLARE @num_rooms INT 
    DECLARE @card_id INT 
    DECLARE @posting_date DATETIME = Getdate() 
    DECLARE @due_date DATETIME = Dateadd(wk, 2, Getdate()) 
    --Give the customer 2 weeks to pay their bill 
    DECLARE @start_date DATETIME 
    DECLARE @end_date DATETIME 
    DECLARE @check_ins INT 
    DECLARE @check_outs INT 
    DECLARE @total_cost NUMERIC(12, 2) 
    DECLARE @fees NUMERIC(12, 2) 

    BEGIN TRANSACTION 

  BEGIN try 
      --Retrieve some account pricing data: 
      SELECT @mly_cost = monthly_cost, 
             @room_cost = room_cost, 
             @tran_cost = transaction_cost 
      FROM   t_client c 
             INNER JOIN t_service s 
                     ON c.plan_id = s.plan_id 
      WHERE  client_id = @client_id 

      --Make sure this client has kept up with their payments 
      --if they have missed 3 payments, deactivate their account 
      IF (SELECT Count(*) 
          FROM   t_invoice 
          WHERE  client_id = @client_id 
                 AND paid_flag = 0) = 3 
        BEGIN 
            PRINT( 
'Error: This client missed 3 payments and their account has been deactivated: ' 
+ CONVERT(VARCHAR(50), @client_id) ) 

    UPDATE t_client 
    SET    is_active_flag = 0 
    WHERE  client_id = @client_id 
END 

    --if the client missed less than 3 payments, charge their account additional fees 
    IF (SELECT Count(*) 
        FROM   t_invoice 
        WHERE  client_id = @client_id 
               AND paid_flag = 0) BETWEEN 1 AND 3 
      BEGIN 
          SET @fees = 24.99 
      END 
    ELSE 
      BEGIN 
          SET @fees = 0 
      END 

    --if this this the clients first invoice, use the date they joined as the service start date. 
    IF NOT EXISTS (SELECT TOP 1 * 
                   FROM   t_invoice 
                   WHERE  client_id = @client_id) 
      BEGIN 
          SET @start_date = (SELECT date_joined 
                             FROM   t_client 
                             WHERE  client_id = @client_id) 
      END 
    --otherwise find the end_date of their previous invoice, if this SP was run 
    --for a single client in order for them to change their plan, this logic should "pro-rate" their invoice. 
    ELSE 
      BEGIN 
          SELECT TOP 1 @start_date = service_end_date 
          FROM   t_invoice 
          WHERE  client_id = @client_id 
          ORDER  BY invoice_id DESC 
      END 

    --did the client terminate their service? 
    IF (SELECT date_terminated 
        FROM   t_client 
        WHERE  client_id = @client_id) IS NOT NULL 
       AND (SELECT date_terminated 
            FROM   t_client 
            WHERE  client_id = @client_id) > @start_date 
      --if so, and the termination date is after the derived start date...use their termination date as the end date. 
      BEGIN            SET @end_date = (SELECT date_terminated                             FROM   t_client                             WHERE  client_id = @client_id)        END      ELSE        BEGIN            SET @end_date = @posting_date        END       --Figure out the total cost for all the rooms the client has      SELECT @room_cost = @room_cost * Count(*),             @num_rooms = Count(*)      FROM   t_hotel h             INNER JOIN t_room r                     ON h.hotel_id = r.hotel_id      WHERE  h.client_id = @client_id       --Figure out the total cost for all transactions (Check-ins)      SELECT @check_ins = Count(*)      FROM   t_client c             INNER JOIN t_hotel h                     ON c.client_id = h.client_id             INNER JOIN t_guest g                     ON h.hotel_id = g.hotel_id      WHERE  g.checkin_time IS NOT NULL             AND g.checkin_time BETWEEN @start_date AND @end_date             AND c.client_id = @client_id       --Figure out the total cost for all transactions (Check-outs)      SELECT @check_outs = Count(*)      FROM   t_client c             INNER JOIN t_hotel h                     ON c.client_id = h.client_id             INNER JOIN t_guest g                     ON h.hotel_id = g.hotel_id      WHERE  g.checkout_time IS NOT NULL             AND g.checkout_time BETWEEN @start_date AND @end_date             AND c.client_id = @client_id       --incase there were not check-ins or checkouts at any of the clients hotels      IF ( @check_ins = 0           AND @check_outs = 0 )        BEGIN            SET @tran_cost = 0        END      ELSE        BEGIN            SET @tran_cost = ( @tran_cost * @check_ins ) +                             ( @tran_cost * @check_outs )        END       SET @total_cost = @room_cost + @tran_cost + @mly_cost + @fees       --which credit card will be used? 
    SELECT @card_id = cc.card_id 
    FROM   t_client c 
           INNER JOIN t_payment p 
                   ON c.client_id = p.client_id 
           INNER JOIN t_creditcard cc 
                   ON cc.card_id = p.card_id 
    WHERE  p.default_pmt = 1 
           AND c.client_id = @client_id 

    /*************************************************************** 
    This section can be used to process a credit card transaction... 
    we will assume it is successful. 
    ****************************************************************/ 
    INSERT INTO t_invoice 
                (client_id, 
                 date, 
                 service_start_date, 
                 service_end_date, 
                 check_ins, 
                 check_outs, 
                 card_id, 
                 total_cost, 
                 paid_flag, 
                 payment_due_date, 
                 num_rooms, 
                 fees) 
    VALUES     (@client_id, 
                @posting_date, 
                @start_date, 
                @end_date, 
                @check_ins, 
                @check_outs, 
                @card_id, 
                @total_cost, 
                0, 
                @due_date, 
                @num_rooms, 
                @fees) 

    SET @check_ins = NULL 
    SET @check_outs = NULL 
    SET @start_date = NULL 
    SET @end_date = NULL 
    SET @card_id = NULL 
    SET @total_cost = NULL 
    SET @fees = NULL 
    SET @num_rooms = NULL 

    COMMIT TRANSACTION 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT @client_id      AS client_id, 
             Error_message() AS error 
  END catch 

go 

CREATE PROCEDURE [dbo].[Sp_auto_remove_reservations] 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP will curse through each clients hotel and automatically make available rooms that were reserved  
    and not checked into. The guest that was to check into the room will be charged for one nights stay and a check-out time will 
    be added to the guests record. 
     
    How to: 
        exec sp_auto_remove_reservations 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      DECLARE @cur_guest_id INT 
      DECLARE cur CURSOR FOR 
        --First find which guests have not checked-in yet who reserved a room 
        SELECT g.guest_id 
        FROM   t_guest g 
               INNER JOIN t_hotel h 
                       ON g.hotel_id = h.hotel_id 
        WHERE  g.reservation_start_date IS NOT NULL 
               --Which guests reserved a room? 
               AND g.reservation_end_date IS NOT NULL 
               AND g.checkin_time IS NULL --Which guests have not checked in? 
               AND g.reservation_start_date = CONVERT(DATE, Getdate()) 
               --What data should this query effect? 
               AND h.checkin_deadline < CONVERT(TIME, Getdate()) 
      --What data meets the check-in deadline criteria? 
      OPEN cur 

      FETCH next FROM cur INTO @cur_guest_id 

      WHILE @@FETCH_STATUS = 0 
        BEGIN 
            --Check out the current guest in the cursor 
            EXEC Sp_check_out_process 
              @guest_id = @cur_guest_id, 
              @remove_fees = 0 

            FETCH next FROM cur INTO @cur_guest_id 
        END 

      CLOSE cur 

      DEALLOCATE cur 

      COMMIT TRANSACTION 

      SELECT 0         errorNum, 
             'success' AS status 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               errorNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_change_client_service] @user_id   VARCHAR(12), 
                                                  @client_id INT, 
                                                  @plan_id   INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP will be used to generate invoices for a client that decides to change their service plan. 
    --see [sp_auto_generate_client_invoice_srvc_change] 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
        BEGIN 
            --Make sure the previous invoice was paid prior to allowing a service change 
            IF (SELECT TOP 1 paid_flag 
                FROM   t_invoice 
                WHERE  client_id = 2 
                ORDER  BY invoice_id DESC) = 1 
              BEGIN 
                  EXEC [Sp_auto_generate_client_invoice_srvc_change] 
                    @client_id 

                  UPDATE t_client 
                  SET    plan_id = @plan_id 
                  WHERE  client_id = @client_id 

                  COMMIT TRANSACTION 

                  SELECT 0         AS errNum, 
                         'success' AS status 
              END 

            --If it was not paid, raise an error 
            IF (SELECT TOP 1 paid_flag 
                FROM   t_invoice 
                WHERE  client_id = 2 
                ORDER  BY invoice_id DESC) = 0 
              BEGIN 
                  RAISERROR( 
        'Error: Please pay your past invoices prior to changing service plans', 
        16 
        ,3 
        ) 
        END 

            --If no invoice was generated in the past, just let the client change their plan. 
            --This will usually happen when a client first sets up there account and wants to change their plan 
            IF (SELECT TOP 1 paid_flag 
                FROM   t_invoice 
                WHERE  client_id = 2 
                ORDER  BY invoice_id DESC) IS NULL 
              BEGIN 
                  UPDATE t_client 
                  SET    plan_id = @plan_id 
                  WHERE  client_id = @client_id 

                  --Make sure the account has the no more than the maximum number of active hotels their new plan allows. 
                  DECLARE @continue INT 

                  EXEC Sp_chk_hotels 
                    @client_id, 
                    @continue output 

                  IF @continue = 0 
                    BEGIN 
                        RAISERROR( 
'Error: You have reached your maximum number of active hotels. PLease deactivate hotels to change your plan.' 
,16,5) 
END 
ELSE 
  BEGIN 
      COMMIT TRANSACTION 

      SELECT 0         AS errNum, 
             'success' AS status 
  END 
END 
END 
ELSE 
  BEGIN 
      RAISERROR( 
      'Error: You are not authorized to change the client''s service plan',16,6) 
  END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_check_in] @user_id             VARCHAR(12), 
                                     @room_id             INT = NULL, 
                                     @fname               VARCHAR(50) = NULL, 
                                     @lname               VARCHAR(50) = NULL, 
                                     @drivers_license     VARCHAR(17) = NULL, 
                                     @vehicle_license     VARCHAR(10) = NULL, 
                                     @street              VARCHAR(100) = NULL, 
                                     @city                VARCHAR(50) = NULL, 
                                     @state               CHAR(2) = NULL, 
                                     @zipcode             INT = NULL, 
                                     @card_number         VARCHAR(17) = NULL, 
                                     @card_security_code  VARCHAR(4) = NULL, 
                                     @card_expiration_yr  INT = NULL, 
                                     @card_expiration_mth INT = NULL, 
                                     @total_occupants     INT = NULL, 
                                     @paid                BIT = 0, 
                                     @was_reserved        BIT = 0, 
                                     @guest_id            INT = NULL 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: Used to check in a guest. 
     
    How to: 
        exec [sp_check_in] 
        @user_id = 'eponere1', 
      @room_id = 5, 
      @fname = 'John', 
      @lname = 'Smith', 
      @drivers_license = 'S-123-456-789-222', 
      @vehicle_license = '2EGG90', 
      @street = '123 Pez Ln', 
      @city = 'Towson', 
      @state = 'MD', 
      @zipcode = '21110', 
      @card_number = '36521258964125364', 
      @card_security_code = '005', 
      @card_expiration_yr = 2015, 
      @card_expiration_mth = 7, 
      @total_occupants = 2 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      /********************************/ 
      DECLARE @hotel_id INT 

      IF @guest_id IS NULL 
        BEGIN 
            SET @hotel_id = (SELECT hotel_id 
                             FROM   t_room 
                             WHERE  room_id = @room_id) 
        END 
      ELSE 
        BEGIN 
            SELECT @hotel_id = hotel_id, 
                   @room_id = room_id 
            FROM   t_guest 
            WHERE  guest_id = @guest_id 
        END 

      --Does the user have the authority to check-in a guest, and into the requested hotel? If so, continue... 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
            'CLIENT', 'MANAGER', 'FRONT DESK CLERK' ) 
         AND (SELECT client_id 
              FROM   t_user 
              WHERE  Lower(user_id) = Lower(@user_id)) = (SELECT client_id 
                                                          FROM   t_hotel 
                                                          WHERE 
             hotel_id = @hotel_id) 
        BEGIN 
        /******************************/ 
            --Only let the guest check-in if the room is available and if the room is not reserved at the time of check-in 
            IF (SELECT status 
                FROM   t_room 
                WHERE  room_id = @room_id) NOT IN ( 'VACANT' ) 
              BEGIN 
                  RAISERROR ('Error: The chosen room is not available.',16,6) 
              END 

        /******************************/ 
            --Check to see if this particular guest has any unpaid stays at the hotel they are checking into 
            IF EXISTS (SELECT TOP 1 * 
                       FROM   t_guest 
                       WHERE  hotel_id = @hotel_id 
                              AND paid_flag = 0 
                              AND drivers_license = @drivers_license) 
              BEGIN 
                  RAISERROR('Error: This customer has an unpaid invoice.',16,7) 
              END 

        /******************************/ 
            --Only add the guests records if the guest did not reserve the room in advance 
            IF @guest_id IS NULL 
              BEGIN 
                  --create a variable to catch the address id when the address table is updated 
                  DECLARE @address_id INT 
                  DECLARE @address_out_tbl TABLE 
                    ( 
                       id INT 
                    ) 

                  --insert the guests address into the address table 
                  INSERT INTO t_address 
                              (street, 
                               city, 
                               state, 
                               zipcode) 
                  output      inserted.address_id 
                  INTO @address_out_tbl(id) 
                  VALUES      (@street, 
                               @city, 
                               @state, 
                               @zipcode) 

                  --assign the address id to the @address_id variable 
                  SET @address_id = (SELECT id 
                                     FROM   @address_out_tbl) 

              /******************************/ 
                  --create a variable to catch the guests card id when the creditcard table is updated 
                  DECLARE @guest_card_id INT 
                  DECLARE @guest_card_out_tbl TABLE 
                    ( 
                       id INT 
                    ) 

                  --add the guests payment method 
                  INSERT INTO t_creditcard 
                              (card_holder_name, 
                               number, 
                               security_code, 
                               expiration_yr, 
                               expiration_mth) 
                  output      inserted.card_id 
                  INTO @guest_card_out_tbl(id) 
                  VALUES      (@fname + ' ' + @lname, 
                               @card_number, 
                               @card_security_code, 
                               @card_expiration_yr, 
                               @card_expiration_mth) 

                  --assign the card id to a variable 
                  SET @guest_card_id = (SELECT id 
                                        FROM   @guest_card_out_tbl) 

              /******************************/ 
                  --get the daily rate of the room that the client is checking into 
                  DECLARE @rate NUMERIC(6, 2) 

                  SELECT @rate = rate 
                  FROM   t_hotel_room_rate 
                  WHERE  rate_id IN (SELECT rate_id 
                                     FROM   t_room 
                                     WHERE  room_id = @room_id) 

                  /******************************/ 
                  DECLARE @crrTimestamp DATETIME = (SELECT Getdate()) 

                  --Now update the guest table with all the applicable data `about the guest 
                  INSERT INTO t_guest 
                              (hotel_id, 
                               room_id, 
                               first_name, 
                               last_name, 
                               drivers_license, 
                               vehicle_license, 
                               address_id, 
                               checkin_time, 
                               total_occupants, 
                               daily_rate, 
                               card_id, 
                               paid_flag, 
                               removed_fees_flag) 
                  VALUES     (@hotel_id, 
                              @room_id, 
                              @fname, 
                              @lname, 
                              @drivers_license, 
                              @vehicle_license, 
                              @address_id, 
                              @crrTimestamp, 
                              @total_occupants, 
                              @rate, 
                              @guest_card_id, 
                              @paid, 
                              0) 
              END 
            ELSE 
              BEGIN 
                  UPDATE t_guest 
                  SET    checkin_time = Getdate() 
                  WHERE  guest_id = @guest_id 
              END 

            --And set the room status to NOTVACANT 
            UPDATE t_room 
            SET    status = 'NOTVACANT' 
            WHERE  room_id = @room_id 

            INSERT INTO t_room_history 
                        (user_id, 
                         room_id, 
                         to_status, 
                         log_date_time) 
            VALUES      (@user_id, 
                         @room_id, 
                         'NOTVACANT', 
                         Getdate()) 

            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR ( 
'Error: You are either not authorized to check-in guests, or check-in guests into the requested hotel.' 
,16,5); 
END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_check_out] @user_id     VARCHAR(12), 
                                      @guest_id    INT, 
                                      @remove_fees BIT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: Used to check out a guest. 
     
    How to: 
        exec [sp_check_out] 
        @user_id = 'eponere1', 
        @guest_id = 7, 
        @remove_fees = 0 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /********************************/ 
      --Does the user have the authority to check-out a guest, and from the requested hotel? If so, continue... 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
            'CLIENT', 'MANAGER', 'FRONT DESK CLERK' ) 
         AND (SELECT client_id 
              FROM   t_user 
              WHERE  Lower(user_id) = Lower(@user_id)) = (SELECT client_id 
                                                          FROM   t_hotel 
                                                          WHERE 
             hotel_id = (SELECT hotel_id 
                         FROM   t_guest 
                         WHERE  guest_id 
                        = @guest_id)) 
        BEGIN 
            EXEC Sp_check_out_process 
              @guest_id, 
              @remove_fees 

            DECLARE @room_id INT = (SELECT room_id 
               FROM   t_guest 
               WHERE  guest_id = @guest_id) 

            IF (SELECT Count(*) 
                FROM   t_room 
                WHERE  room_id = @room_id 
                       AND status = 'NOTVACANT') = 1 
              BEGIN 
                  UPDATE t_room 
                  SET    status = 'DIRTY' 
                  WHERE  room_id = @room_id 
                  --The room does not need to be cleaned  
                  INSERT INTO t_room_history 
                              (user_id, 
                               room_id, 
                               to_status, 
                               log_date_time) 
                  VALUES      (@user_id, 
                               @room_id, 
                               'DIRTY', 
                               Getdate()) 
              END 

            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR ( 
'Error: You are not authorized to check-in guests, or check-out guests from the requested hotel.' 
,16,5); 
END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_check_out_process] @guest_id    INT, 
                                              @remove_fees BIT 
/********************************* 
Author: Evangelos Poneres 
Notes: Used to check out a guest without the use of a username. 
*********************************/ 
AS 
    --If the guest has already been checked_out, throw an error 
    IF (SELECT checkout_time 
        FROM   t_guest 
        WHERE  guest_id = @guest_id) IS NOT NULL 
      BEGIN 
          RAISERROR ('Error: This guest has already been checked out.',16,6); 
      END 

    --First lets find out the guests length-of-stay, and daily rate... 
    DECLARE @checkin_dt DATETIME 
    DECLARE @checkout_dt DATETIME = Getdate() 
    DECLARE @daily_rate NUMERIC(6, 2) 
    DECLARE @hotel_id INT 
    DECLARE @room_id INT 
    DECLARE @occupants INT 
    DECLARE @LOS INT --Length -of Stay 
    DECLARE @total_cost NUMERIC(12, 2) = 0 
    DECLARE @fees NUMERIC(12, 2) = 0 

    SELECT @checkin_dt = checkin_time, 
           @daily_rate = daily_rate, 
           @hotel_id = hotel_id, 
           @occupants = total_occupants, 
           @room_id = room_id 
    FROM   t_guest 
    WHERE  guest_id = @guest_id 

    IF ( @checkin_dt IS NULL ) 
      BEGIN 
          --In this scenario, the guest may have made a reservation and never checked in... 
          --so we will charge them for one day's stay 
          SET @checkin_dt = @checkout_dt 
      END 

    SET @LOS = Datediff(dd, @checkin_dt, @checkout_dt) 

    IF @LOS = 0 
      BEGIN 
          --A zero LOS means the guest might have been automatically check_out for not checking into a reserved room 
          SET @LOS = 1 
      END 

    PRINT ( @LOS ) 

    --Now get the hotels tax rate 
    DECLARE @tax NUMERIC(4, 2) 

    SELECT @tax = tax 
    FROM   t_tax 
    WHERE  state = (SELECT state 
                    FROM   t_address 
                    WHERE  address_id = (SELECT address_id 
                                         FROM   t_hotel 
                                         WHERE  hotel_id = @hotel_id)) 

    --Did the guest incur any additional fees like a late-checkout or exceed the max-occupant limit. 
    DECLARE @checkout_deadline TIME 
    DECLARE @max_occupants INT 
    DECLARE @late_check_out_cost NUMERIC(5, 2) 
    DECLARE @additional_occupant_cost NUMERIC(5, 2) 

    SELECT @checkout_deadline = checkout_deadline, 
           @late_check_out_cost = late_checkout_cost, 
           @additional_occupant_cost = additional_occupant_cost 
    FROM   t_hotel 
    WHERE  hotel_id = @hotel_id 

    IF (SELECT CONVERT(TIME, @checkout_dt)) > @checkout_deadline 
      BEGIN 
          SET @fees = @fees + @late_check_out_cost 
      END 

    IF ( @occupants > (SELECT max_occupants 
                       FROM   t_room 
                       WHERE  room_id = @room_id) ) 
      BEGIN 
          SET @fees = @fees + @additional_occupant_cost 
      END 

    --Now calculate the total cost for the guests stay 
    SET @total_cost = ( ( @LOS * @daily_rate ) + @fees ) 

    --If the fees are to be removed, do so 
    IF @remove_fees = 1 
      BEGIN 
          SET @total_cost = @total_cost - @fees 
      END 

    --Add the tax if applicable 
    IF ( @tax > 0 ) 
      BEGIN 
          SET @total_cost = @total_cost + ( @total_cost * ( @tax / 100 ) ) 
      END 

/*************************************************************** 
This section can be used to process a credit card transaction... 
we will assume it is successful. 
****************************************************************/ 
    --Now update the guests record  
    UPDATE t_guest 
    SET    checkout_time = @checkout_dt, 
           checkin_time = @checkin_dt,--incase there was no check_in value. 
           paid_flag = 1, 
           current_tax = @tax, 
           removed_fees_flag = @remove_fees, 
           total_cost = @total_cost 
    WHERE  guest_id = @guest_id 

go  

CREATE PROCEDURE [dbo].[Sp_chk_hotels] @client_id INT, 
                                  @continue  BIT = NULL output 
AS 
    /*********************************** 
    Author: Evangelos Poneres 
    Notes: This SP will be called whenever a clients number of hotels needs to be checked against their max allowed hotels 
    ***********************************/ 
    DECLARE @max_allowed_hotels INT 
    DECLARE @curr_active_hotel_cnt INT = (SELECT Count(*) 
       FROM   t_hotel 
       WHERE  client_id = @client_id 
              AND is_active = 1) 

    SELECT @max_allowed_hotels = max_hotels 
    FROM   t_service 
    WHERE  plan_id = (SELECT plan_id 
                      FROM   t_client 
                      WHERE  client_id = @client_id) 

    --If the user has not their max_hotel_cnt, let them continue. 
    IF @curr_active_hotel_cnt <= @max_allowed_hotels 
      BEGIN 
          SET @continue = 1 

          RETURN 
      END 
    ELSE 
      BEGIN 
          SET @continue = 0 

          RETURN 
      END 

go  

CREATE PROCEDURE [dbo].[Sp_delete_guest_reservation] @guest_id INT 
AS 
    /*************************** 
    Author: Evangelos Poneres 
    Notes: We need the end users to be able to completely delete a GUESTS reservation. 
    ***************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      --Make sure the guest has not already checked-in or out...hence, they only have a reservation 
      IF (SELECT checkout_time 
          FROM   t_guest 
          WHERE  guest_id = 20) IS NULL 
         AND (SELECT checkin_time 
              FROM   t_guest 
              WHERE  guest_id = 20) IS NULL 
        BEGIN 
            DECLARE @address_id INT = (SELECT address_id 
               FROM   t_guest 
               WHERE  guest_id = @guest_id) 
            DECLARE @card_id INT = (SELECT card_id 
               FROM   t_guest 
               WHERE  guest_id = @guest_id) 

            DELETE FROM t_guest 
            WHERE  guest_id = @guest_id 

            DELETE FROM t_address 
            WHERE  address_id = @address_id 

            DELETE FROM t_creditcard 
            WHERE  card_id = @card_id 
        END 

      SELECT 0         AS errNum, 
             'success' AS status 

      COMMIT TRANSACTION 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_delete_hotel] @hotel_id INT 
AS 
    BEGIN TRANSACTION 

  BEGIN try 
      DECLARE @address_id INT 

      SELECT @address_id = address_id 
      FROM   t_address 
      WHERE  address_id = (SELECT address_id 
                           FROM   t_hotel 
                           WHERE  hotel_id = @hotel_id) 

      DELETE FROM t_hotel 
      WHERE  hotel_id = @hotel_id 

      DELETE FROM t_address 
      WHERE  address_id = @address_id 

      SELECT 0         AS errNum, 
             'success' AS status 

      COMMIT TRANSACTION 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_delete_user] @user_id     VARCHAR(12), 
                                        @del_user_id VARCHAR(12) 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: When a Client wants to delete a user in their account, this SP can assist 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /*********************************/ 
      --First see if the user is allowed to add users 
      --Is the user a client and is the specified user they want to delete, one of their users?  
      --If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
         AND @del_user_id IN (SELECT user_id 
                              FROM   t_user 
                              WHERE  client_id = (SELECT client_id 
                                                  FROM   t_user 
                                                  WHERE  Lower(user_id) = Lower( 
                                                         @user_id) 
                                                 )) 
        BEGIN 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 

            --Don't delete the user, just set their is_active_flag to disabled. 
            UPDATE t_user 
            SET    is_active_flag = 0 
            WHERE  Lower(user_id) = Lower(@del_user_id) 

            --if the update was successful, then commit 
            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR( 
            'Error: You are not authorized to delete users from this account.' 
            ,16,3) 
        END 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_get_available_rooms] @user_id            VARCHAR(12), 
                                                @hotel_id           INT = NULL, 
                                                @reserve_start_date DATETIME, 
                                                @reserve_end_date   DATETIME, 
                                                @exclude_reserved   BIT = 0 
AS 
  /********************************* 
  Author: Evangelos Poneres 
  Notes: This SP will retrieve all available rooms for a particular hotel and their price. 
  The user will be required to supply a date range to find rooms that are available for that duration. 
  If the date range is invalid, an error will be thrown. 
   
  How to: 
      exec sp_get_available_rooms 
      @user_id = 'eponere1', 
    @hotel_id = 33, 
    @reserve_start_date = '2013-11-24', 
    @reserve_end_date = '2013-11-24', 
    @exclude_reserved = 0 
  **********************************/ 
  BEGIN try 
      --A user might not have any hotels created when their account is first created. 
      --But we still need a reultset... 
      IF @hotel_id IS NULL 
          OR @hotel_id = '' 
        BEGIN 
            SELECT NULL AS room_id, 
                   NULL AS room_num, 
                   NULL AS description, 
                   NULL AS rate, 
                   NULL AS status 

            RETURN 
        END 

      --Does the user have the authority to reserve a room? If so, continue... 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
            'CLIENT', 'MANAGER', 'FRONT DESK CLERK' ) 
         AND (SELECT client_id 
              FROM   t_user 
              WHERE  Lower(user_id) = Lower(@user_id)) = (SELECT client_id 
                                                          FROM   t_hotel 
                                                          WHERE 
             hotel_id = @hotel_id) 
        BEGIN 
            IF ( @reserve_start_date > @reserve_end_date ) 
              BEGIN 
                  RAISERROR( 
'Error: The start date can''t be greater than the end date. Or a date in the past.' 
,16,1) 
END 
ELSE 
  BEGIN 
      --Get all rooms that are available w/o a reservation 
      SELECT r.room_id, 
             r.room_name AS room_num, 
             r.description, 
             hrr.rate, 
             'VACANT'    AS status 
      INTO   #temp 
      FROM   t_room r 
             INNER JOIN t_hotel_room_rate hrr 
                     ON r.rate_id = hrr.rate_id 
      WHERE  hotel_id = @hotel_id 
             AND Upper(status) = 'VACANT' 
             AND room_id NOT IN (SELECT room_id 
                                 FROM   t_guest 
                                 WHERE  checkin_time IS NULL 
                                        AND checkout_time IS NULL 
                                        AND ( ( reservation_start_date BETWEEN 
                                                @reserve_start_date AND 
                                                @reserve_end_date ) 
                                               OR ( reservation_end_date BETWEEN 
                                                    @reserve_start_date AND 
                                                    @reserve_end_date 
                                                  ) ) 
                                    ) 
      UNION ALL 
      --Now get all rooms that are reserved and available for check-in by the person that reserved the room. 
      SELECT r.room_id, 
             r.room_name AS room_num, 
             r.description, 
             hrr.rate, 
             'RESERVED' 
      FROM   t_room r 
             INNER JOIN t_hotel_room_rate hrr 
                     ON r.rate_id = hrr.rate_id 
      WHERE  hotel_id = @hotel_id 
             AND Upper(status) = 'VACANT' 
             AND room_id IN (SELECT room_id 
                             FROM   t_guest 
                             WHERE  checkin_time IS NULL 
                                    AND checkout_time IS NULL 
                                    AND ( ( reservation_start_date BETWEEN 
                                            @reserve_start_date AND 
                                            @reserve_end_date 
                                          ) 
                                           OR ( reservation_end_date BETWEEN 
                                                @reserve_start_date AND 
                                                @reserve_end_date ) ) 
                            ) 
      ORDER  BY hrr.rate, 
                r.room_name ASC 

      --We might not want to see the reserved rooms on the homepage 
      IF @exclude_reserved = 1 
        BEGIN 
            DELETE FROM #temp 
            WHERE  status = 'RESERVED' 
        END 

      SELECT * 
      FROM   #temp 
  END 
END 
ELSE 
  BEGIN 
      RAISERROR( 
      'Error: You are not authorized to view rooms for the requested hotel.',16, 
      2) 
  END 
END try 

  BEGIN catch 
      SELECT 1               errorNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_get_client] @user_id VARCHAR(12) 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: Used to retrieve a clients account data 
    *********************************/ 
    SELECT plan_id, 
           company_name, 
           phone, 
           street, 
           city, 
           state, 
           zipcode, 
           email, 
           first_name, 
           last_name 
    FROM   t_client c 
           INNER JOIN t_address a 
                   ON c.address_id = a.address_id 
           INNER JOIN t_user u 
                   ON c.client_id = u.client_id 
    WHERE  Lower(user_id) = Lower(@user_id) 

go  

CREATE PROCEDURE [dbo].[Sp_get_client_invoice] @invoice_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve a single clients invoice in a resultset that defines each aspect of the invoice. 
    *******************************/ 
    DECLARE @client_id INT = (SELECT client_id 
       FROM   t_invoice 
       WHERE  invoice_id = @invoice_id) 

    SELECT 'Invoice ID: '                   AS data, 
           CONVERT(VARCHAR(50), invoice_id) AS content 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Company: ', 
           company_name 
    FROM   t_client 
    WHERE  client_id = @client_id 
    UNION ALL 
    SELECT 'Payment: ', 
           'XXXXXXXXX' + RIGHT(c.number, 4) 
    FROM   t_invoice i 
           INNER JOIN t_creditcard c 
                   ON i.card_id = c.card_id 
    WHERE  i.invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Service Start Date: ', 
           CONVERT(VARCHAR(50), service_start_date) 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Service End Date: ', 
           CONVERT(VARCHAR(50), service_start_date) 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Check Ins: ', 
           CONVERT(VARCHAR(50), check_ins) 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Check Outs: ', 
           CONVERT(VARCHAR(50), check_outs) 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Room Count: ', 
           CONVERT(VARCHAR(50), num_rooms) 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Fees: ', 
           CONVERT(VARCHAR(50), fees) 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 
    UNION ALL 
    SELECT 'Total Charges: ', 
           CONVERT(VARCHAR(50), total_cost) 
    FROM   t_invoice 
    WHERE  invoice_id = @invoice_id 

go  

CREATE PROCEDURE [dbo].[Sp_get_client_invoices] @client_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all of a CLIENTS invoices. 
    *******************************/ 
    SELECT * 
    FROM   t_invoice 
    WHERE  client_id = @client_id 

go 

CREATE PROCEDURE [dbo].[Sp_get_exp_year] 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: Used to retrieve valid expiration years for creditcards. 
    *********************************/ 
    SELECT Year(Getdate()) AS exp_yr 
    UNION ALL 
    SELECT Year(Getdate()) + 1 
    UNION ALL 
    SELECT Year(Getdate()) + 2 
    UNION ALL 
    SELECT Year(Getdate()) + 3 
    UNION ALL 
    SELECT Year(Getdate()) + 4 
    UNION ALL 
    SELECT Year(Getdate()) + 5 
    UNION ALL 
    SELECT Year(Getdate()) + 6 
    UNION ALL 
    SELECT Year(Getdate()) + 7 
    UNION ALL 
    SELECT Year(Getdate()) + 8 
    UNION ALL 
    SELECT Year(Getdate()) + 9 
    UNION ALL 
    SELECT Year(Getdate()) + 10 

CREATE PROCEDURE [dbo].[Sp_get_guest_comments] @user_id VARCHAR(12), 
                                               @type    CHAR(3) 
AS 
  /********************************* 
  Author: Evangelos Poneres 
  Notes: This SP will retrieve the last 50 comments that guests submitted for a given comment type. 
  This is information that a Client may periodically check when they log into the system. 
   
  How to: 
    exec sp_get_guest_comments 
    @user_id = 'eponere1', 
    @type = 'NEG' 
  **********************************/ 
  BEGIN try 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
         'CLIENT', 'MANAGER' ) 
        BEGIN 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 

            SELECT TOP 50 g.guest_id, 
                          g.first_name + ' ' + g.last_name AS guest_name, 
                          gc.comment, 
                          g.checkin_time, 
                          g.checkout_time, 
                          r.room_name                      AS room, 
                          h.name                           AS hotel 
            FROM   t_guest_comments gc 
                   INNER JOIN t_guest g 
                           ON gc.guest_id = g.guest_id 
                   INNER JOIN t_room r 
                           ON r.room_id = g.room_id 
                   INNER JOIN t_hotel h 
                           ON h.hotel_id = g.hotel_id 
                   INNER JOIN t_client c 
                           ON c.client_id = h.client_id 
            WHERE  type = @type 
                   AND c.client_id = @client_id 
            --Make sure the guest stayed at one of the clients hotels.. 
            ORDER  BY comment_id DESC 
        END 
      ELSE 
        BEGIN 
            RAISERROR ('Error: You are not authorized to view guests comments', 
                       16, 
                       1) 
        END 
  END try 

  BEGIN catch 
      SELECT 1               AS errorNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_get_guest_invoice] @user_id     VARCHAR(12), 
                                              @guest_id    INT, 
                                              @remove_fees BIT = NULL 
AS 
  /********************************* 
  Author: Evangelos Poneres 
  Notes: Used to check out a guest. 
   
  How to: 
      exec [sp_get_guest_invoice] 
      @user_id = 'eponere1', 
      @guest_id = 17 
  *********************************/ 
  BEGIN try 
  /********************************/ 
      --Does the user have the authority to view a guests invoice? If so, continue... 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
            'CLIENT', 'MANAGER', 'FRONT DESK CLERK' ) 
         AND (SELECT client_id 
              FROM   t_user 
              WHERE  Lower(user_id) = Lower(@user_id)) = (SELECT client_id 
                                                          FROM   t_hotel 
                                                          WHERE 
             hotel_id = (SELECT hotel_id 
                         FROM   t_guest 
                         WHERE  guest_id 
                        = @guest_id)) 
        BEGIN 
            --First lets find out the guests length-of-stay, and daily rate... 
            DECLARE @checkin_dt DATETIME 
            DECLARE @checkout_dt DATETIME = Getdate() 
            DECLARE @daily_rate NUMERIC(6, 2) 
            DECLARE @hotel_id INT 
            DECLARE @room_id INT 
            DECLARE @occupants INT 
            DECLARE @LOS INT --Length -of Stay 
            DECLARE @total_cost NUMERIC(12, 2) = 0 
            DECLARE @fees NUMERIC(12, 2) = 0 
            DECLARE @remove_fees2 BIT 

            SELECT @checkin_dt = checkin_time, 
                   @daily_rate = daily_rate, 
                   @hotel_id = hotel_id, 
                   @occupants = total_occupants, 
                   @room_id = room_id, 
                   @remove_fees2 = removed_fees_flag 
            FROM   t_guest 
            WHERE  guest_id = @guest_id 

            SET @LOS = Datediff(dd, @checkin_dt, @checkout_dt) 

            --Now get the hotels tax rate 
            DECLARE @tax NUMERIC(4, 2) 

            SELECT @tax = tax 
            FROM   t_tax 
            WHERE  state = (SELECT state 
                            FROM   t_address 
                            WHERE  address_id = (SELECT address_id 
                                                 FROM   t_hotel 
                                                 WHERE  hotel_id = @hotel_id)) 

            --Did the guest incur any additional fees like a late-checkout or exceed the max-occupant limit. 
            DECLARE @checkout_deadline TIME 
            DECLARE @max_occupants INT 
            DECLARE @late_check_out_cost NUMERIC(5, 2) 
            DECLARE @additional_occupant_cost NUMERIC(5, 2) 

            SELECT @checkout_deadline = checkout_deadline, 
                   @late_check_out_cost = late_checkout_cost, 
                   @additional_occupant_cost = additional_occupant_cost 
            FROM   t_hotel 
            WHERE  hotel_id = @hotel_id 

            IF (SELECT CONVERT(TIME, @checkout_dt)) > @checkout_deadline 
              BEGIN 
                  SET @fees = @fees + @late_check_out_cost 
              END 

            IF ( @occupants > (SELECT max_occupants 
                               FROM   t_room 
                               WHERE  room_id = @room_id) ) 
              BEGIN 
                  SET @fees = @fees + @additional_occupant_cost 
              END 

            --A zero LOS means the guest might have been automatically check_out for not checking into a reserved room 
            IF @LOS = 0 
              BEGIN 
                  SET @LOS = 1 
              END 

            --Now calculate the total cost for the guests stay 
            SET @total_cost = ( ( @LOS * @daily_rate ) + @fees ) 

            --If the users wants to see the invoice without the fee, they will feed a 1, 
            IF @remove_fees IS NULL 
              BEGIN 
                  SET @remove_fees = @remove_fees2 
              END 

            --Otherwise, the original value will be used 0 
            IF @remove_fees = 1 
                OR @remove_fees2 = 1 
              BEGIN 
                  SET @total_cost = @total_cost - @fees 
                  SET @fees = 0 
              END 

            DECLARE @sub_total NUMERIC(12, 2) = @total_cost 

            --Add the tax if applicable 
            IF ( @tax > 0 ) 
              BEGIN 
                  SET @total_cost = @total_cost + ( @total_cost * ( @tax / 100 ) 
                                                  ) 
              END 

            --Now show the end user the invoice with all the necessary elements 
            DECLARE @hotel_name VARCHAR(50) = (SELECT name 
               FROM   t_hotel 
               WHERE  hotel_id = @hotel_id) 
            DECLARE @address_line_1 VARCHAR(100) = (SELECT street 
               FROM   t_address 
               WHERE  address_id = (SELECT address_id 
                                    FROM   t_hotel 
                                    WHERE  hotel_id = @hotel_id)) 
            DECLARE @address_line_2 VARCHAR(100) = (SELECT 
                    city + ', ' + state + ' ' 
                      + CONVERT(VARCHAR(10), zipcode) 
               FROM   t_address 
               WHERE  address_id = (SELECT address_id 
                                    FROM   t_hotel 
                                    WHERE  hotel_id = @hotel_id)) 
            DECLARE @room_name VARCHAR(50) = (SELECT room_name 
               FROM   t_room 
               WHERE  room_id = @room_id) 
            DECLARE @room_description VARCHAR(50) = (SELECT description 
               FROM   t_room 
               WHERE  room_id = @room_id) 

            SELECT 'Hotel ID:'                     AS dataType, 
                   CONVERT(VARCHAR(50), @hotel_id) AS content 
            UNION ALL 
            SELECT 'Hotel:', 
                   @hotel_name 
            UNION ALL 
            SELECT 'Address_line_1: ', 
                   @address_line_1 
            UNION ALL 
            SELECT 'Address_line_2: ', 
                   @address_line_2 
            UNION ALL 
            SELECT 'Check In:', 
                   CONVERT(VARCHAR(50), @checkin_dt) 
            UNION ALL 
            SELECT 'Check Out:', 
                   CONVERT(VARCHAR(50), @checkout_dt) 
            UNION ALL 
            SELECT 'Room #:', 
                   @room_name 
            UNION ALL 
            SELECT 'Room Description:', 
                   @room_description 
            UNION ALL 
            SELECT 'Length of Stay:', 
                   CONVERT(VARCHAR(50), @LOS) 
            UNION ALL 
            SELECT 'Total Occupants:', 
                   CONVERT(VARCHAR(50), @occupants) 
            UNION ALL 
            SELECT 'Sub Total:', 
                   CONVERT(VARCHAR(50), @sub_total) 
            UNION ALL 
            SELECT 'Fees:', 
                   CONVERT(VARCHAR(50), @fees) 
            UNION ALL 
            SELECT 'Tax:', 
                   CONVERT(VARCHAR(50), @tax) 
            UNION ALL 
            SELECT 'Total:', 
                   CONVERT(VARCHAR(50), @total_cost) 
        END 
      ELSE 
        BEGIN 
            RAISERROR ('Error: You are not authorized to view a guests invoice.' 
                       , 
                       16,5) 
            ; 
        END 
  END try 

  BEGIN catch 
      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_get_guest_reservations] @hotel_id INT = NULL, 
                                              @guest_id INT = NULL 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: Depending on which input parameter is passed, this SP will either  
      1.retrieve all GUESTS that have reserved a room at a particular hotel (@hotel) 
      2.or, retrieve one guests reservation attributes (@guest) 
    *******************************/ 
    IF @hotel_id IS NOT NULL 
      SELECT 
      g.guest_id, 
             r.room_name                                         AS room_num, 
             r.hotel_id, 
             g.drivers_license, 
             g.vehicle_license, 
             g.total_occupants, 
             a.street, 
             a.city, 
             a.state, 
             a.zipcode, 
             g.first_name, 
             g.last_name, 
             'XXXXXXXXXXX' + RIGHT(c.number, 4)                  AS number, 
             c.expiration_mth, 
             c.expiration_yr, 
             CONVERT(VARCHAR(10), g.reservation_start_date, 120) AS 
      reservation_start_date 
      , 
             CONVERT(VARCHAR(10), g.reservation_end_date, 120)   AS 
      reservation_end_date 
      FROM   t_guest g 
             INNER JOIN t_address a 
                     ON g.address_id = a.address_id 
             INNER JOIN t_creditcard c 
                     ON g.card_id = c.card_id 
             INNER JOIN t_room r 
                     ON g.room_id = r.room_id 
      WHERE  checkin_time IS NULL 
             AND checkout_time IS NULL 
             AND g.hotel_id = @hotel_id 
      ORDER  BY reservation_start_date DESC 

    IF @guest_id IS NOT NULL 
      SELECT 
      g.guest_id, 
             r.room_name                                         AS room_num, 
             r.hotel_id, 
             g.drivers_license, 
             g.vehicle_license, 
             g.total_occupants, 
             a.street, 
             a.city, 
             a.state, 
             a.zipcode, 
             g.first_name, 
             g.last_name, 
             'XXXXXXXXXXX' + RIGHT(c.number, 4)                  AS number, 
             c.expiration_mth, 
             c.expiration_yr, 
             CONVERT(VARCHAR(10), g.reservation_start_date, 120) AS 
      reservation_start_date 
      , 
             CONVERT(VARCHAR(10), g.reservation_end_date, 120)   AS 
      reservation_end_date 
      FROM   t_guest g 
             INNER JOIN t_address a 
                     ON g.address_id = a.address_id 
             INNER JOIN t_creditcard c 
                     ON g.card_id = c.card_id 
             INNER JOIN t_room r 
                     ON g.room_id = r.room_id 
      WHERE  checkin_time IS NULL 
             AND checkout_time IS NULL 
             AND g.guest_id = @guest_id 
      ORDER  BY reservation_start_date DESC 

go

CREATE PROCEDURE [dbo].[Sp_get_guests] @hotel_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve GUESTS that have checked-in, but have not checked-out or a particular hotel. 
    This populates the guest who need to be Checked-out eventually. 
    *******************************/ 
    SELECT g.*, 
           r.room_name 
    FROM   t_guest g 
           INNER JOIN t_room r 
                   ON g.room_id = r.room_id 
    WHERE  checkin_time IS NOT NULL 
           AND checkout_time IS NULL 
           AND g.hotel_id = @hotel_id 

go  

CREATE PROCEDURE [dbo].[Sp_get_hotel] @hotel_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve a particular hotels attributes. 
    *******************************/ 
    SELECT h.hotel_id, 
           h.name, 
           h.checkin_deadline         AS cid, 
           h.checkout_deadline        AS cod, 
           h.additional_occupant_cost AS aoc, 
           h.late_checkout_cost       AS lcc, 
           a.street, 
           a.city, 
           a.state, 
           a.zipcode, 
           h.is_active 
    FROM   t_hotel h 
           INNER JOIN t_address a 
                   ON h.address_id = a.address_id 
    WHERE  h.hotel_id = @hotel_id 

go  

CREATE PROCEDURE [dbo].[Sp_get_hotels] @userid VARCHAR(12) 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all the hotels a user has access to. 
    *All hotels for a particular user if they are a CLIENT 
    *THe hotel a user is assigned to if they are not a CLIENT. 
    *******************************/ 
    CREATE TABLE #temp 
      ( 
         hotel_id  INT, 
         name      VARCHAR(50), 
         street    VARCHAR(100), 
         city      VARCHAR(50), 
         state     CHAR(2), 
         zipcode   INT, 
         is_active BIT 
      ) 

    --If the user is a client, grant them access to all hotels, otherwise, just to the hotel they were assigned. 
    IF (SELECT Upper(r.title) 
        FROM   t_user u 
               INNER JOIN t_role r 
                       ON u.role_id = r.role_id 
        WHERE  Lower(u.user_id) = Lower(@userid)) = 'CLIENT' 
      BEGIN 
          INSERT INTO #temp 
          SELECT hotel_id, 
                 name, 
                 street, 
                 city, 
                 state, 
                 zipcode, 
                 is_active 
          FROM   t_hotel h 
                 INNER JOIN t_address a 
                         ON h.address_id = a.address_id 
          WHERE  client_id = (SELECT client_id 
                              FROM   t_user 
                              WHERE  Lower(user_id) = Lower(@userid)) 
      END 
    ELSE 
      BEGIN 
          INSERT INTO #temp 
          SELECT hotel_id, 
                 name, 
                 street, 
                 city, 
                 state, 
                 zipcode, 
                 is_active 
          FROM   t_hotel h 
                 INNER JOIN t_address a 
                         ON h.address_id = a.address_id 
          WHERE  hotel_id = (SELECT hotel_id 
                             FROM   t_user 
                             WHERE  Lower(user_id) = Lower(@userid)) 
      END 

    SELECT * 
    FROM   #temp 

go  

CREATE PROCEDURE [dbo].[Sp_get_mth] 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Date: 11-2-2013 
    Notes: Used to retrieve valid expiration months for creditcards. 
    *********************************/ 
    DECLARE @itr INT = 1 

    CREATE TABLE #temp 
      ( 
         mth_name VARCHAR(6), 
         mth_num  INT 
      ) 

    WHILE @itr < 13 
      BEGIN 
          INSERT INTO #temp 
          SELECT CONVERT(VARCHAR(2), @itr) + ' ' 
                 + Upper(LEFT(Datename(month, '2013-'+CONVERT(VARCHAR(2), @itr)+ 
                 '-01') 
                 , 3) 
                 ), 
                 @itr 

          SET @itr = @itr + 1 
      END 

    SELECT * 
    FROM   #temp 

go  

CREATE PROCEDURE [dbo].[Sp_get_news] 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Date: 11-1-2013 
    Notes: When a client logs into the system, a news feed that  
    VITS wants to share with all of its customers will appear. 
     
    How to: 
        exec [sp_get_news] 
    **********************************/ 
    SELECT TOP 5 CONVERT(VARCHAR(50), [date], 100) AS [Time Stamp], 
                 content                           AS [News] 
    FROM   t_news 
    ORDER  BY date DESC 

go  

CREATE PROCEDURE [dbo].[Sp_get_payments] @client_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all the creditcards a CLIENT has input as payment options. 
    *******************************/ 
    SELECT cr.card_id, 
           card_holder_name, 
           'XXXXXXXXXXX' + RIGHT(number, 4) AS number, 
           security_code, 
           expiration_mth, 
           expiration_yr, 
           default_pmt 
    FROM   t_client c 
           INNER JOIN t_payment p 
                   ON c.client_id = p.client_id 
           INNER JOIN t_creditcard cr 
                   ON p.card_id = cr.card_id 
    WHERE  c.client_id = @client_id 

go  

CREATE PROCEDURE [dbo].[Sp_get_plans] 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve the available plans a potential  
    customers may choose from when registering themselves as a CLIENT 
    *******************************/ 
    SELECT plan_id, 
           'Monthly Rate: $' 
           + CONVERT(VARCHAR(50), monthly_cost) + ' ; ' 
           + CONVERT(VARCHAR(50), max_hotels) 
           + ' Hotel(s); ' + '$' 
           + CONVERT(VARCHAR(50), room_cost) 
           + ' per Room; ' + '$' 
           + CONVERT(VARCHAR(50), transaction_cost) 
           + ' per Transaction' AS plan_desc 
    FROM   t_service 

go  

CREATE PROCEDURE [dbo].[Sp_get_rates] @client_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all the rates which belongs to a particular CLIENT 
    *******************************/ 
    SELECT * 
    FROM   t_hotel_room_rate 
    WHERE  client_id = @client_id 

    SELECT * 
    FROM   t_hotel_room_rate 
    WHERE  client_id = @client_id 
    ORDER  BY description, 
              rate 

go 

CREATE PROCEDURE [dbo].[Sp_get_roles] 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all the roles that a CLIENT may assign to their employees. 
    *******************************/ 
    SELECT * 
    FROM   t_role 
    WHERE  Upper(title) <> 'CLIENT' 

go  

CREATE PROCEDURE [dbo].[Sp_get_room_history] @hotel_id INT, 
                                        @user_id  VARCHAR(12) = NULL 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Date: 10-31-2013 
    Notes: Clients / Managers may check to see who cleaned, checked-in, or checked-out a guest from a particular 
    *********************************/ 
    IF @user_id IS NULL 
      BEGIN 
          SELECT r.hotel_id, 
                 rh.[user_id], 
                 r.room_name, 
                 rh.to_status, 
                 rh.log_date_time 
          FROM   t_room_history rh 
                 INNER JOIN t_room r 
                         ON rh.room_id = r.room_id 
          WHERE  @hotel_id = @hotel_id 
          ORDER  BY log_date_time 
      END 
    ELSE 
      BEGIN 
          SELECT r.hotel_id, 
                 rh.[user_id], 
                 r.room_name, 
                 rh.to_status, 
                 rh.log_date_time 
          FROM   t_room_history rh 
                 INNER JOIN t_room r 
                         ON rh.room_id = r.room_id 
          WHERE  @hotel_id = @hotel_id 
                 AND Lower(user_id) = Lower(@user_id) 
          ORDER  BY log_date_time 
      END 

go  

CREATE PROCEDURE [dbo].[Sp_get_rooms] @hotel_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all rooms within a given hotel along with the room's price 
    *******************************/ 
    SELECT r.*, 
           hrr.rate 
    FROM   t_room r 
           INNER JOIN t_hotel_room_rate hrr 
                   ON r.rate_id = hrr.rate_id 
    WHERE  hotel_id = @hotel_id 

go  

CREATE PROCEDURE [dbo].[Sp_get_states] 
AS 
/******************************* 
Author: Evangelos Poneres 
Notes: This SP will retrieve all states from the t_tax table  
to populate any drop-down list that requires the user to pick a state 
*******************************/ 
    --The first value is an invalid state which forces the user to pick a valid state 
    SELECT '(-)' AS state 
    UNION ALL 
    SELECT state 
    FROM   t_tax 

go 

CREATE PROCEDURE [dbo].[Sp_get_times] 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all times during a day in 30 min. increments. 
    *******************************/ 
    DECLARE @i INT = 0 
    DECLARE @time TIME = '12:00' 

    CREATE TABLE #time 
      ( 
         time_val TIME, 
         time_txt VARCHAR(15) 
      ) 

    WHILE @i < 48 
      BEGIN 
          INSERT INTO #time 
                      (time_val, 
                       time_txt) 
          SELECT @time                            AS time_val, 
                 CONVERT(VARCHAR(15), @time, 100) AS time_txt 

          SET @time = Dateadd(mi, 30, @time) 
          SET @i = @i + 1 
      END 

    SELECT * 
    FROM   #time 

    DROP TABLE #time 

go  

CREATE PROCEDURE [dbo].[Sp_get_url] @userid VARCHAR(12) 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve the urls that a given user may access based on their role_id 
    *******************************/ 
    SELECT * 
    FROM   (SELECT Replace(Upper(LEFT(url, Len(url) - 5)), '_', ' ') AS url_name 
                   , 
                   url 
            FROM   t_user_role 
            WHERE  role_id IN (SELECT role_id 
                               FROM   t_user 
                               WHERE  Lower(user_id) = Lower(@userid)) 
            UNION ALL 
            SELECT 'HOME', 
                   'home.aspx') Q 
    ORDER  BY url_name 

go  

CREATE PROCEDURE [dbo].[Sp_get_users] @client_id INT 
AS 
    /******************************* 
    Author: Evangelos Poneres 
    Notes: This SP will retrieve all of a guests users (employees) and their credentials. 
    *******************************/ 
    SELECT hotel_id, 
           user_id, 
           password, 
           first_name, 
           last_name, 
           email, 
           r.role_id, 
           title, 
           is_active_flag 
    FROM   t_user u 
           INNER JOIN t_role r 
                   ON u.role_id = r.role_id 
    WHERE  client_id = @client_id 
           AND Upper(title) <> 'CLIENT' 
           AND is_active_flag = 1 

go  

CREATE PROCEDURE [dbo].[Sp_get_wake_up_times] @hotel_id INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: The SP will return all guests that need to be woken up that have not checked out yet. 
    This result set can be used by a telecom system to issue automated wake-up calls. 
    *********************************/ 
    SELECT w.alarm_id, 
           r.room_name, 
           w.alarm_time, 
           g.last_name, 
           r.phone 
    FROM   t_wakeup w 
           INNER JOIN t_guest g 
                   ON w.guest_id = g.guest_id 
           INNER JOIN t_room r 
                   ON r.room_id = g.room_id 
    WHERE  g.checkout_time IS NULL 
           AND g.checkin_time IS NOT NULL 
           AND g.hotel_id = @hotel_id 
           AND w.alarm_time >= Getdate() 

go

CREATE PROCEDURE [dbo].[Sp_get_wake_up_times_telecom] 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: The SP will return all guests that need to be woken up that have not checked out yet. 
    This result set can be used by a telecom system to issue automated wake-up  calls. 
    *********************************/ 
    SELECT w.alarm_time, 
           r.phone 
    FROM   t_wakeup w 
           INNER JOIN t_guest g 
                   ON w.guest_id = g.guest_id 
           INNER JOIN t_room r 
                   ON r.room_id = g.room_id 
    WHERE  g.checkout_time IS NULL 
           AND g.checkin_time IS NOT NULL 

go  

CREATE PROCEDURE [dbo].[Sp_lost_found_item] @user_id     VARCHAR(12), 
                                            @hotel_id    INT = NULL, 
                                            @description VARCHAR(500) = NULL, 
                                            @item_id     INT = NULL 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP will allow a user to input a lost or found item into the system 
    --all users can perform this operation, so no authorization is needed 
    How to: 
      --lost item 
      exec sp_lost_found_item @user_id = 'eponere1', @hotel_id = 1, @description = 'keys' 
       
      --found item 
      exec sp_lost_found_item @user_id = 'eponere1', @item_id = 0 
    **********************************/ 
 BEGIN TRANSACTION 
  BEGIN try 
      --if an item is being inserted into the system...the item_id will be null 
      IF @item_id IS NULL 
        BEGIN 
            INSERT INTO t_lost_items 
                        (description, 
                         hotel_id, 
                         lost_date, 
                         user_lost) 
            VALUES      (@description, 
                         @hotel_id, 
                         Getdate(), 
                         @user_id) 
        END 
      ELSE 
        BEGIN 
            UPDATE t_lost_items 
            SET    found_date = Getdate(), 
                   user_found = @user_id 
            WHERE  item_id = @item_id 
        END 

      COMMIT TRANSACTION 
      SELECT 0         AS errorNum, 
             'success' AS status 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1 AS errorNum, 
             Error_message() 
  END catch  

CREATE PROCEDURE [dbo].[Sp_purge_data_3yr] 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: Purges data from the t_guest tables that is older than 3 years old based on checkout_time 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
	DELETE FROM t_wakeup 
	FROM   t_wakeup w 
      INNER JOIN t_guest g 
      ON w.guest_id = g.guest_id 
	WHERE  g.checkout_time < Dateadd(year, -3, Getdate()) 
	
      SELECT address_id, 
             card_id 
      INTO   #delete 
      FROM   t_guest 
      WHERE  checkout_time < Dateadd(year, -3, Getdate()) 

      DELETE FROM t_guest 
      WHERE  checkout_time < Dateadd(year, -3, Getdate()) 

      DELETE FROM t_address 
      WHERE  address_id IN (SELECT address_id 
                            FROM   #delete) 

      DELETE FROM t_creditcard 
      WHERE  card_id IN (SELECT card_id 
                         FROM   #delete) 

      COMMIT TRANSACTION 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT Error_message() 
  END catch  

CREATE PROCEDURE [dbo].[Sp_reserve_room] @user_id             VARCHAR(12), 
                                         @room_id             INT, 
                                         @fname               VARCHAR(50), 
                                         @lname               VARCHAR(50), 
                                         @drivers_license     VARCHAR(17), 
                                         @vehicle_license     VARCHAR(10) = NULL, 
                                         @street              VARCHAR(100), 
                                         @city                VARCHAR(50), 
                                         @state               CHAR(2), 
                                         @zipcode             INT, 
                                         @card_number         VARCHAR(17), 
                                         @card_security_code  VARCHAR(4), 
                                         @card_expiration_yr  INT, 
                                         @card_expiration_mth INT, 
                                         @reserve_start_date  DATETIME, 
                                         @reserve_end_date    DATETIME, 
                                         @total_occupants     INT, 
                                         @paid                BIT = 0, 
                                         @removed_fees_flag   BIT = 0 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: Used to reserve a room for guest. 
     
    How to: 
        exec [sp_reserve_room] 
        @user_id = 'eponere1', 
      @room_id = 4, 
      @fname = 'John', 
      @lname = 'Conner', 
      @drivers_license = 'S-123-456-789-222', 
      @vehicle_license = '2EDF34', 
      @street = '123 Highland Ave', 
      @city = 'Towson', 
      @state = 'MD', 
      @zipcode = '21110', 
      @card_number = '36521258964125364', 
      @card_security_code = '005', 
      @card_expiration_yr = 2015, 
      @card_expiration_mth = 7, 
      @reserve_start_date = '2013-11-05 21:46:27.370', 
      @reserve_end_date = '2013-11-05 21:46:27.370', 
      @total_occupants = 2 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      /********************************/ 
      DECLARE @hotel_id INT = (SELECT hotel_id 
         FROM   t_room 
         WHERE  room_id = @room_id) 

      --Does the user have the authority to reserve a room? If so, continue... 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) IN ( 
            'CLIENT', 'MANAGER', 'FRONT DESK CLERK' ) 
         AND (SELECT client_id 
              FROM   t_user 
              WHERE  Lower(user_id) = Lower(@user_id)) = (SELECT client_id 
                                                          FROM   t_hotel 
                                                          WHERE 
             hotel_id = @hotel_id) 
        BEGIN 
        /******************************/ 
            --Make sure the dates supplied are valid 
            IF ( @reserve_start_date > @reserve_end_date ) 
                OR ( @reserve_start_date <= Dateadd(day, Datediff(day, 0, 
                                                         Getdate( 
                                                         )) 
                                                         - 1 
                                            , 0) 
                   ) 
              BEGIN 
                  RAISERROR ('Error: The dates supplied are invalid.',16,8); 
              END 

            --See if the room is available to be reserved 
            IF @room_id IN (SELECT room_id 
                            FROM   t_room 
                            WHERE  room_id IN (SELECT room_id 
                                               FROM   t_guest 
                                               WHERE 
                                   checkin_time IS NULL 
                                   AND checkout_time IS NULL 
                                   AND ( ( @reserve_start_date 
                                           BETWEEN 
                                           reservation_start_date 
                                           AND 
                                           reservation_end_date 
                                         ) 
                                          OR ( @reserve_end_date 
                                               BETWEEN 
                                               reservation_start_date 
                                               AND 
                                               reservation_end_date ) 
                                       ) 
                                    OR ( reservation_start_date 
                                         BETWEEN 
                                         @reserve_start_date AND 
                                         @reserve_end_date ) 
                                    OR ( reservation_end_date BETWEEN 
                                         @reserve_start_date AND 
                                         @reserve_end_date ))) 
              BEGIN 
                  RAISERROR ( 
        'Error: The room is already reserved for the chosen date range.' 
        , 
        16,6); 
              END 

        /******************************/ 
            --create a variable to catch the address id when the address table is updated 
            DECLARE @address_id INT 
            DECLARE @address_out_tbl TABLE 
              ( 
                 id INT 
              ) 

            --insert the guests address into the address table 
            INSERT INTO t_address 
                        (street, 
                         city, 
                         state, 
                         zipcode) 
            output      inserted.address_id 
            INTO @address_out_tbl(id) 
            VALUES      (@street, 
                         @city, 
                         @state, 
                         @zipcode) 

            --assign the address id to the @address_id variable 
            SET @address_id = (SELECT id 
                               FROM   @address_out_tbl) 

        /******************************/ 
            --create a variable to catch the guests card id when the creditcard table is updated 
            DECLARE @guest_card_id INT 
            DECLARE @guest_card_out_tbl TABLE 
              ( 
                 id INT 
              ) 

            --add the guests payment method 
            INSERT INTO t_creditcard 
                        (card_holder_name, 
                         number, 
                         security_code, 
                         expiration_yr, 
                         expiration_mth) 
            output      inserted.card_id 
            INTO @guest_card_out_tbl(id) 
            VALUES      (@fname + ' ' + @lname, 
                         @card_number, 
                         @card_security_code, 
                         @card_expiration_yr, 
                         @card_expiration_mth) 

            --assign the card id to a variable 
            SET @guest_card_id = (SELECT id 
                                  FROM   @guest_card_out_tbl) 

        /******************************/ 
            --get the daily rate of the room that the client is checking into 
            DECLARE @rate NUMERIC(6, 2) 

            SELECT @rate = rate 
            FROM   t_hotel_room_rate 
            WHERE  rate_id IN (SELECT rate_id 
                               FROM   t_room 
                               WHERE  room_id = @room_id) 

        /******************************/ 
            --Now update the guest table with all the applicable data `about the guest 
            INSERT INTO t_guest 
                        (hotel_id, 
                         room_id, 
                         first_name, 
                         last_name, 
                         drivers_license, 
                         vehicle_license, 
                         address_id, 
                         reservation_start_date, 
                         reservation_end_date, 
                         total_occupants, 
                         daily_rate, 
                         card_id, 
                         paid_flag, 
                         removed_fees_flag) 
            VALUES     (@hotel_id, 
                        @room_id, 
                        @fname, 
                        @lname, 
                        @drivers_license, 
                        @vehicle_license, 
                        @address_id, 
                        @reserve_start_date, 
                        @reserve_end_date, 
                        @total_occupants, 
                        @rate, 
                        @guest_card_id, 
                        @paid, 
                        @removed_fees_flag) 

            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR ('Error: You are not authorized to reserve a room.',16,5); 
        END 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go  

CREATE PROCEDURE Sp_revenue_volumes @yr  INT, 
                               @rpt INT 
AS 
    IF @rpt = 1 
      BEGIN 
          SELECT name                         AS Hotel, 
                 CONVERT(INT, Round([1], 0))  AS JAN, 
                 CONVERT(INT, Round([2], 0))  AS FEB, 
                 CONVERT(INT, Round([3], 0))  AS MAR, 
                 CONVERT(INT, Round([4], 0))  AS APR, 
                 CONVERT(INT, Round([5], 0))  AS MAY, 
                 CONVERT(INT, Round([6], 0))  AS JUN, 
                 CONVERT(INT, Round([7], 0))  AS JUL, 
                 CONVERT(INT, Round([8], 0))  AS AUG, 
                 CONVERT(INT, Round([9], 0))  AS SEP, 
                 CONVERT(INT, Round([10], 0)) AS OCT, 
                 CONVERT(INT, Round([11], 0)) AS NOV, 
                 CONVERT(INT, Round([12], 0)) AS [DEC] 
          FROM   (SELECT Month(checkout_time) mth, 
                         total_cost, 
                         name 
                  FROM   t_guest gst 
                         INNER JOIN t_hotel htl 
                                 ON gst.hotel_id = htl.hotel_id 
                  WHERE  Year(checkout_time) = @yr) g 
                 PIVOT (Sum(total_cost) 
                       FOR mth IN([1], 
                                  [2], 
                                  [3], 
                                  [4], 
                                  [5], 
                                  [6], 
                                  [7], 
                                  [8], 
                                  [9], 
                                  [10], 
                                  [11], 
                                  [12])) AS pvt 
      END 

    IF @rpt = 2 
      BEGIN 
          SELECT name AS Hotel, 
                 [1]  AS JAN, 
                 [2]  AS FEB, 
                 [3]  AS MAR, 
                 [4]  AS APR, 
                 [5]  AS MAY, 
                 [6]  AS JUN, 
                 [7]  AS JUL, 
                 [8]  AS AUG, 
                 [9]  AS SEP, 
                 [10] AS OCT, 
                 [11] AS NOV, 
                 [12] AS [DEC] 
          FROM   (SELECT Month(checkout_time) mth, 
                         name, 
                         Count(*)             AS vol 
                  FROM   t_guest gst 
                         INNER JOIN t_hotel htl 
                                 ON gst.hotel_id = htl.hotel_id 
                  WHERE  Year(checkout_time) = @yr 
                  GROUP  BY Month(checkout_time), 
                            name) g 
                 PIVOT (Sum(vol) 
                       FOR mth IN([1], 
                                  [2], 
                                  [3], 
                                  [4], 
                                  [5], 
                                  [6], 
                                  [7], 
                                  [8], 
                                  [9], 
                                  [10], 
                                  [11], 
                                  [12])) AS pvt 
      END  

CREATE PROCEDURE [dbo].[Sp_search_guests] @hotel_id   INT, 
                                     @search_val VARCHAR(50) 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: To be used when searching for a guest, they may use first, last name or drivers license 
    *********************************/ 
    SET @search_val = Lower(@search_val) 

    SELECT TOP 15 g.guest_id, 
                  r.room_name, 
                  g.first_name, 
                  g.last_name, 
                  g.drivers_license, 
                  g.checkin_time, 
                  g.checkout_time, 
                  g.reservation_start_date, 
                  g.reservation_end_date 
    FROM   t_guest g 
           INNER JOIN t_room r 
                   ON g.room_id = r.room_id 
    WHERE  ( Lower(first_name) LIKE '%' + @search_val + '%' 
              OR Lower(last_name) LIKE '%' + @search_val + '%' 
              OR Lower(drivers_license) LIKE '%' + @search_val + '%' 
              OR Lower(r.room_name) LIKE '%' + @search_val + '%' ) 
           AND g.hotel_id = @hotel_id 

go  

CREATE PROCEDURE [dbo].[Sp_search_guests_checked_in] @hotel_id   INT, 
                                                @search_val VARCHAR(50) 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: To be used when searching for a guest, they may use first, last name or drivers license 
    *********************************/ 
    SELECT TOP 15 g.guest_id, 
                  r.room_name, 
                  g.first_name, 
                  g.last_name, 
                  g.drivers_license, 
                  CONVERT(DATE, g.checkin_time)  AS checkin_time, 
                  CONVERT(DATE, g.checkout_time) AS checkout_time 
    FROM   t_guest g 
           INNER JOIN t_room r 
                   ON g.room_id = r.room_id 
    WHERE  ( first_name LIKE '%' + @search_val + '%' 
              OR last_name LIKE '%' + @search_val + '%' 
              OR drivers_license LIKE '%' + @search_val + '%' ) 
           AND g.hotel_id = @hotel_id 
           AND g.checkout_time IS NULL 
           AND g.checkin_time IS NOT NULL 
go  

CREATE PROCEDURE [dbo].[Sp_set_default_payment] @card_id INT 
AS 
    /*********************************** 
    Author: Evangelos Poneres 
    Notes: To be used for changing a client's default payment method 
    ***********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      DECLARE @client_id INT = (SELECT client_id FROM   t_payment 
         WHERE  card_id = @card_id) 

      UPDATE t_payment SET    default_pmt = 0 
      WHERE  client_id = @client_id 

      UPDATE t_payment 
      SET    default_pmt = 1 
      WHERE  card_id = @card_id 

      COMMIT TRANSACTION 
  END try 
  BEGIN catch 
      ROLLBACK TRANSACTION 
  END catch 
go 

CREATE PROCEDURE [dbo].[Sp_set_room_to_vacant] @user_id VARCHAR(12), 
                                               @room_id INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP will allow a user to set a rooms status as VACANT, after it has been cleaned. 
    **********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      UPDATE t_room 
      SET    status = 'VACANT' 
      WHERE  room_id = @room_id 

      INSERT INTO t_room_history 
                  (user_id, 
                   room_id, 
                   to_status, 
                   log_date_time) 
      VALUES      (@user_id, 
                   @room_id, 
                   'VACANT', 
                   Getdate()) 

      COMMIT TRANSACTION 

      SELECT 0         AS errorNum, 
             'success' AS status 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1 AS errorNum, 
             Error_message() 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_update_client] @user_id      VARCHAR(12), 
                                          @email        VARCHAR(100), 
                                          @first_name   VARCHAR(50), 
                                          @last_name    VARCHAR(50), 
                                          @street       VARCHAR(100), 
                                          @city         VARCHAR(50), 
                                          @state        CHAR(2), 
                                          @zipcode      INT, 
                                          @phone        VARCHAR(50), 
                                          @plan_id      INT, 
                                          @company_name VARCHAR(50) 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: When a new customer wants to modify their account settings, this SP can be used. 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      --Make sure the user is has a client role. 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
        BEGIN 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 
            DECLARE @address_id INT = (SELECT address_id 
               FROM   t_client 
               WHERE  client_id = @client_id) 
            DECLARE @orig_plan_id INT = (SELECT plan_id 
               FROM   t_client 
               WHERE  client_id = @client_id) 

            --IF the client decided to change their plan, then an invoice needs to be generated for there service to date. 
            IF @plan_id <> @orig_plan_id 
              BEGIN 
                  EXEC Sp_change_client_service 
                    @user_id, 
                    @client_id, 
                    @plan_id 
              END 

            UPDATE t_client 
            SET    company_name = @company_name, 
                   plan_id = @plan_id, 
                   phone = @phone 
            WHERE  client_id = @client_id 

            UPDATE t_user 
            SET    first_name = @first_name, 
                   last_name = @last_name, 
                   email = @email 
            WHERE  Lower(user_id) = Lower(@user_id) 

            UPDATE t_address 
            SET    street = @street, 
                   city = @city, 
                   state = @state, 
                   zipcode = @zipcode 
            WHERE  address_id = @address_id 

            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR('Error: You are not authorized to make account changes.', 
                      16, 
                      1) 
        END 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_update_hotel] @hotel_id                 INT, 
                                         @user_id                  VARCHAR(12), 
                                         @hotel_name               VARCHAR(50), 
                                         @checkin_deadline         TIME, 
                                         @checkout_deadline        TIME, 
                                         @additional_occupant_cost NUMERIC(5, 2), 
                                         @late_checkout_cost       NUMERIC(5, 2), 
                                         @street                   VARCHAR(100), 
                                         @city                     VARCHAR(50), 
                                         @state                    CHAR(2), 
                                         @zipcode                  INT, 
                                         @is_active                BIT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: This SP can be used when a Client wants to modify a hotel 
    **********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
        BEGIN 
            DECLARE @address_id INT 

            SELECT @address_id = address_id 
            FROM   t_hotel 
            WHERE  hotel_id = @hotel_id 

            UPDATE t_hotel 
            SET    name = @hotel_name, 
                   checkin_deadline = @checkin_deadline, 
                   checkout_deadline = @checkout_deadline, 
                   additional_occupant_cost = @additional_occupant_cost, 
                   late_checkout_cost = @late_checkout_cost, 
                   is_active = @is_active 
            WHERE  hotel_id = @hotel_id 

            UPDATE t_address 
            SET    street = @street, 
                   city = @city, 
                   state = @state, 
                   zipcode = @zipcode 
            WHERE  address_id = @address_id 

            --Make sure the user did not exceed their maximum number of hotels 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 
            DECLARE @continue BIT 

            EXEC Sp_chk_hotels 
              @client_id, 
              @continue output 

            IF @continue = 0 
              BEGIN 
                  RAISERROR( 
        'Error: You have reached your maximum number of active hotels.', 
        16 
        ,5) 
              END 
            ELSE 
              BEGIN 
                  COMMIT TRANSACTION 

                  SELECT 0         AS errNum, 
                         'success' AS status 
              END 
        END 
      ELSE 
        BEGIN 
            RAISERROR ('Error: You are not authorized to modify hotels.',16,5); 
        END 
  /*********************************/ 
  END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go  

CREATE PROCEDURE [dbo].[Sp_update_room] @user_id       VARCHAR(12), 
                                        @hotel_id      INT, 
                                        @room_id       INT, 
                                        @room_name     VARCHAR(50), 
                                        @description   VARCHAR(50), 
                                        @phone         VARCHAR(50), 
                                        @max_occupants INT, 
                                        @rate_id       INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: To be used when a Client wants to update a room in one of their hotels. 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /*********************************/ 
      --First see if the user is allowed to update rooms 
      --Is the user a client and does the room/hotel belong to them? If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
         AND (SELECT client_id 
              FROM   t_hotel 
              WHERE  hotel_id = (SELECT hotel_id 
                                 FROM   t_room 
                                 WHERE  room_id = @room_id)) = (SELECT client_id 
                                                                FROM   t_user 
                                                                WHERE 
                 Lower(user_id) = Lower(@user_id)) 
        BEGIN 
            UPDATE t_room 
            SET    room_name = @room_name, 
                   hotel_id = @hotel_id, 
                   description = @description, 
                   phone = @phone, 
                   max_occupants = @max_occupants, 
                   rate_id = @rate_id 
            WHERE  room_id = @room_id 

            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR ( 
'Error: You are either not authorized to add/modify a room in the requested hotel, the rate does not belong to your account, or a duplicate room number exists.' 
,16,1) 
END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      BEGIN 
          SELECT 1               AS errNum, 
                 Error_message() AS status 
      END 
  END catch 

go 

CREATE PROCEDURE [dbo].[Sp_update_user] @user_id     VARCHAR(12), 
                                        @mod_user_id VARCHAR(12), 
                                        @password    VARCHAR(12), 
                                        @email       VARCHAR(100), 
                                        @first_name  VARCHAR (50), 
                                        @last_name   VARCHAR (50), 
                                        @role_id     INT, 
                                        @hotel_id    INT 
AS 
    /********************************* 
    Author: Evangelos Poneres 
    Notes: When a Client wants to update a user in their account, this SP can assist 
    *********************************/ 
    BEGIN TRANSACTION 

  BEGIN try 
  /*********************************/ 
      --First see if the user is allowed to add users 
      --Is the user a client and is the specified hotel part of their account, and is the user the want to modify, one of their users?  
      --If so, continue 
      IF (SELECT Upper(title) 
          FROM   t_role 
          WHERE  role_id = (SELECT role_id 
                            FROM   t_user 
                            WHERE  Lower(user_id) = Lower(@user_id))) = 'CLIENT' 
         AND @hotel_id IN (SELECT hotel_id 
                           FROM   t_hotel 
                           WHERE  client_id = (SELECT client_id 
                                               FROM   t_user 
                                               WHERE  Lower(user_id) = Lower( 
                                                      @user_id) 
                                              )) 
         AND @mod_user_id IN (SELECT user_id 
                              FROM   t_user 
                              WHERE  client_id = (SELECT client_id 
                                                  FROM   t_user 
                                                  WHERE  Lower(user_id) = Lower( 
                                                         @user_id) 
                                                 )) 
        BEGIN 
            DECLARE @client_id INT = (SELECT client_id 
               FROM   t_user 
               WHERE  Lower(user_id) = Lower(@user_id)) 

            UPDATE t_user 
            SET    user_id = @mod_user_id, 
                   password = @password, 
                   email = @email, 
                   first_name = @first_name, 
                   last_name = @last_name, 
                   role_id = @role_id, 
                   hotel_id = @hotel_id 
            WHERE  Lower(user_id) = Lower(@mod_user_id) 

            --if the update was successful, then commit 
            COMMIT TRANSACTION 

            SELECT 0         AS errNum, 
                   'success' AS status 
        END 
      ELSE 
        BEGIN 
            RAISERROR( 
'Error: You are either not authorized to add users, or to add users to the specified hotel.' 
,16,3) 
END 
END try 

  BEGIN catch 
      ROLLBACK TRANSACTION 

      SELECT 1               AS errNum, 
             Error_message() AS status 
  END catch 
go  

CREATE PROCEDURE [dbo].[Sp_user_login] @user_id  AS VARCHAR(12), 
                                       @password AS VARCHAR(12) 
AS 
/********************************* 
Author: Evangelos Poneres 
Notes: When a user logs into the system, the web pages they are allowed 
access to as well as some additional details about their account will be loaded. 
Or, they will receive no result-set which means they can't log in...an error will be thrown 
on the client-side application. The web application will assess the result of this 
SP in the order they are returned. The order of this result-set is important. 

**DO NOT REORDER THIS RESULTSET** 

How to: 
    exec [sp_user_login] @user_id = 'eponere1', @password = 'v@ngosKC01' 
**********************************/ 
    --Make sure the user typed in the correct password 
    SET @user_id = Lower(@user_id) 

    IF (SELECT password 
        FROM   t_user 
        WHERE  Lower(user_id) = @user_id) = @password 
       --Make sure the clients account is still active 
       AND (SELECT is_active_flag 
            FROM   t_client 
            WHERE  client_id = (SELECT client_id 
                                FROM   t_user 
                                WHERE  Lower(user_id) = Lower(@user_id))) = 1 
       --Make sure the users account has not been disabled. 
       AND (SELECT is_active_flag 
            FROM   t_user 
            WHERE  Lower(user_id) = @user_id) = 1 
       --And make sure the users hotel is still active or that the user is a client 
       AND ( (SELECT is_active 
              FROM   t_hotel 
              WHERE  hotel_id = (SELECT hotel_id 
                                 FROM   t_user 
                                 WHERE  Lower(user_id) = @user_id)) = 1 
              OR (SELECT Upper(title) 
                  FROM   t_role 
                  WHERE  role_id = (SELECT role_id 
                                    FROM   t_user 
                                    WHERE  Lower(user_id) = @user_id)) = 
                 'CLIENT' ) 
      BEGIN 
          SELECT 'client_id'                     AS dataType, 
                 CONVERT(VARCHAR(50), client_id) AS content 
          FROM   t_user 
          WHERE  user_id = @user_id 
          UNION ALL 
          SELECT 'user_role', 
                 title 
          FROM   t_role 
          WHERE  role_id IN (SELECT role_id 
                             FROM   t_user 
                             WHERE  Lower(user_id) = @user_id) 
          UNION ALL 
          SELECT 'user', 
                 @user_id 
      END 

go  
TRIGGERS

CREATE TRIGGER [dbo].[clean_room_first] 
ON [dbo].[t_room] 
after UPDATE 
AS 
  BEGIN 
      --A room should never go from a NOTVACANT to VACANT. It must go into a DIRTY state first. 
      --This trigger will ensure that the room status will follow this business rule. 
      --VACANT --> NOTVACANT 
      --NOTVACANT --> DIRTY 
      --DIRTY-->VACANT 
      DECLARE @from VARCHAR(50) = (SELECT status 
         FROM   deleted) 
      DECLARE @to VARCHAR(50) = (SELECT status 
         FROM   inserted) 

      --Don't worry if the room status stays the same, an update to the rooms attributes may cause this. 
      IF ( @from = @to ) 
        BEGIN 
            RETURN 
        END 
      ELSE 
        ---Make sure the business rules are followed. 
        BEGIN 
            IF ( @from = 'VACANT' 
                 AND @to <> 'NOTVACANT' ) 
                OR ( @from = 'NOTVACANT' 
                     AND @to <> 'DIRTY' ) 
                OR ( @from = 'DIRTY' 
                     AND @to <> 'VACANT' ) 
              BEGIN 
                  ROLLBACK TRANSACTION 

                  RAISERROR( 
                  'Error: The room can''t be changed into an invalid status' 
                  , 
                  16,1) 
              END 
        END 
  END 

go