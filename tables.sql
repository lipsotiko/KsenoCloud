CREATE TABLE t_client
    (
   	 client_id   	INT NOT NULL IDENTITY,
   	 plan_id     	INT NOT NULL,
   	 company_name	VARCHAR(50) NOT NULL,
   	 address_id  	INT NOT NULL,
   	 is_active_flag  BIT NOT NULL,
   	 phone       	VARCHAR(50) NOT NULL,
   	 date_joined 	DATE NOT NULL,
   	 date_terminated DATE NULL
   	 CONSTRAINT pk_client_id PRIMARY KEY (client_id)
    )

CREATE TABLE t_hotel
    (
   	 hotel_id             	INT NOT NULL IDENTITY,
   	 client_id            	INT NOT NULL,
   	 name                 	VARCHAR(50) NOT NULL,
   	 address_id           	INT NOT NULL,
   	 checkin_deadline     	TIME NOT NULL,
   	 checkout_deadline    	TIME NOT NULL,
   	 additional_occupant_cost NUMERIC(5, 2) NOT NULL,
   	 late_checkout_cost   	NUMERIC(5, 2) NOT NULL,
	is_active			BIT NOT NULL,
   	 CONSTRAINT pk_hotel_id PRIMARY KEY (hotel_id)
    )

CREATE TABLE t_room
    (
   	 room_id   	INT NOT NULL IDENTITY,
   	 room_name 	VARCHAR(50) NOT NULL,
   	 hotel_id  	INT NOT NULL,
   	 description   VARCHAR(50) NOT NULL,
   	 phone     	VARCHAR(50) NOT NULL,
   	 status    	VARCHAR(50) NOT NULL,
   	 max_occupants INT NOT NULL,
   	 rate_id   	INT NOT NULL,
   	 CONSTRAINT pk_room_id PRIMARY KEY (room_id)
    )

CREATE TABLE t_hotel_room_rate
    (
   	 rate_id 	INT NOT NULL IDENTITY,
   	 client_id   INT NOT NULL,
   	 description VARCHAR(50) NOT NULL,
   	 rate    	NUMERIC(6, 2) NOT NULL,
   	 CONSTRAINT pk_rate_id PRIMARY KEY (rate_id)
    )


CREATE TABLE t_guest
    (
   	 guest_id           	INT NOT NULL IDENTITY,
	 hotel_id		INT NOT NULL,
   	 room_id            	INT NOT NULL,
   	 first_name         	VARCHAR(50) NOT NULL,
   	 last_name          	VARCHAR(50) NOT NULL,
   	 drivers_license    	VARCHAR(17) NOT NULL,
   	 vehicle_license    	VARCHAR(10) NULL,
   	 address_id         	INT NULL,
   	 checkin_time       	DATETIME NULL,
   	 checkout_time      	DATETIME NULL,
   	 total_occupants    	INT NOT NULL,
   	 daily_rate         	NUMERIC(6, 2) NOT NULL,
   	 card_id            	INT NULL,
   	 paid_flag          	BIT NOT NULL,
   	 current_tax        	NUMERIC(4, 2) NULL,
   	 removed_fees_flag  	BIT NOT NULL,
   	 total_cost         	NUMERIC(12, 2) NULL,
   	 reservation_start_date DATE NULL,
   	 reservation_end_date   DATE NULL,
   	 CONSTRAINT pk_guest_id PRIMARY KEY (guest_id)
    )

CREATE TABLE t_guest_comments
    (
   	 comment_id INT NOT NULL IDENTITY,
   	 guest_id   INT NOT NULL,
   	 comment	VARCHAR(1000) NOT NULL,
   	 type   	VARCHAR(50) NOT NULL,
   	 CONSTRAINT pk_comment_id PRIMARY KEY (comment_id)
    )

CREATE TABLE t_wakeup
(
alarm_id    int NOT NULL IDENTITY,
guest_id    int NOT NULL,
alarm_time    datetime NOT NULL
CONSTRAINT pk_alarm_id PRIMARY KEY (alarm_id)
)

CREATE TABLE t_creditcard
    (
   	 card_id      	INT NOT NULL IDENTITY,
   	 card_holder_name VARCHAR(50) NOT NULL,
   	 number       	VARCHAR(17) NOT NULL,
   	 security_code	VARCHAR(4) NOT NULL,
   	 expiration_yr	INT NOT NULL,
   	 expiration_mth   INT NOT NULL,
   	 CONSTRAINT pk_card_id PRIMARY KEY (card_id)
    )

CREATE TABLE t_payment
    (
   	 payment_id INT NOT NULL IDENTITY,
   	 client_id  INT NOT NULL,
   	 card_id	INT NOT NULL,
	 default_pmt BIT NULL,
   	 CONSTRAINT pk_payment_id PRIMARY KEY (payment_id)
    )

CREATE TABLE t_address
    (
   	 address_id INT NOT NULL IDENTITY,
   	 street 	VARCHAR(100) NOT NULL,
   	 city   	VARCHAR(50) NOT NULL,
   	 state  	CHAR(2) NOT NULL,
   	 zipcode	INT NOT NULL,
   	 CONSTRAINT pk_address_id PRIMARY KEY (address_id)
    )

CREATE TABLE t_tax
    (
   	 state CHAR(2) NOT NULL,
   	 tax   NUMERIC(4, 2) NOT NULL,
   	 CONSTRAINT pk_state PRIMARY KEY (state)
    )

CREATE TABLE t_user
    (
   	 user_id    	VARCHAR(12) NOT NULL,
   	 client_id  	INT NOT NULL,
   	 password   	VARCHAR(12) NOT NULL,
   	 email      	VARCHAR(100) NOT NULL,
   	 first_name 	VARCHAR(50) NOT NULL,
   	 last_name  	VARCHAR(50) NOT NULL,
   	 role_id    	INT NOT NULL,
   	 is_active_flag BIT NOT NULL,
   	 hotel_id   	INT NULL,
   	 CONSTRAINT pk_user_id PRIMARY KEY (user_id)
    )

CREATE TABLE t_role
    (
   	 role_id INT NOT NULL IDENTITY,
   	 title   VARCHAR(50) NOT NULL,
   	 CONSTRAINT pk_role_id PRIMARY KEY (role_id)
    )

CREATE TABLE t_user_role
    (
   	 role_id INT NOT NULL,
   	 url 	VARCHAR(50) NOT NULL,
   	 CONSTRAINT pk_role_id_url PRIMARY KEY (role_id, url)
    )

CREATE TABLE t_lost_items
  (
 	item_id 	INT NOT NULL IDENTITY,
 	description VARCHAR(500) NOT NULL,
 	hotel_id	INT NOT NULL,
 	lost_date   DATE NOT NULL,
 	found_date  DATE NULL,
	user_lost varchar(12) NULL,
	user_found varchar(12) NULL,
 	CONSTRAINT pk_item_id PRIMARY KEY (item_id)
  )

CREATE TABLE t_news
  (
 	news_id INT NOT NULL IDENTITY,
 	date	DATETIME NOT NULL,
 	content VARCHAR(1000) NOT NULL,
 	CONSTRAINT pk_news_id PRIMARY KEY (news_id)
  )

CREATE TABLE t_service
  (
 	plan_id      	INT NOT NULL IDENTITY,
 	max_hotels   	INT NOT NULL,
 	room_cost    	NUMERIC(12, 2) NOT NULL,
 	transaction_cost NUMERIC(12, 2) NOT NULL,
 	monthly_cost 	NUMERIC(12, 2) NOT NULL,
 	CONSTRAINT pk_plan_id PRIMARY KEY (plan_id)
  )

CREATE TABLE t_invoice
  (
 	invoice_id     	INT NOT NULL IDENTITY,
 	client_id      	INT NOT NULL,
 	date           	DATE NOT NULL,
 	service_start_date DATE NOT NULL,
 	service_end_date   DATE NOT NULL,
 	check_ins      	INT NOT NULL,
 	check_outs     	INT NOT NULL,
 	card_id   	 	INT NOT NULL,
 	total_cost     	NUMERIC(12, 2) NOT NULL,
 	paid_flag      	BIT NOT NULL,
 	payment_due_date   DATE NOT NULL,
	num_rooms int not null,
	fees numeric(12,2) not null,
 	CONSTRAINT pk_invoice_id PRIMARY KEY (invoice_id)
  )

ALTER TABLE t_client ADD CONSTRAINT client_fk_plan_id FOREIGN KEY (plan_id) REFERENCES t_service(plan_id)
ALTER TABLE t_client ADD CONSTRAINT client_fk_address_id FOREIGN KEY (address_id) REFERENCES t_address(address_id)

ALTER TABLE t_hotel ADD CONSTRAINT hotel_fk_client_id FOREIGN KEY (client_id) REFERENCES t_client(client_id)
ALTER TABLE t_hotel ADD CONSTRAINT hotel_fk_address_id FOREIGN KEY (address_id) REFERENCES t_address(address_id)

ALTER TABLE t_room ADD CONSTRAINT room_fk_hotel_id FOREIGN KEY (hotel_id) REFERENCES t_hotel(hotel_id)
ALTER TABLE t_room ADD CONSTRAINT room_fk_rate_id FOREIGN KEY (rate_id) REFERENCES t_hotel_room_rate(rate_id)

ALTER TABLE t_hotel_room_rate ADD CONSTRAINT rate_fk_client_id FOREIGN KEY (client_id) REFERENCES t_client(client_id)

ALTER TABLE t_guest ADD CONSTRAINT guest_fk_room_id FOREIGN KEY (room_id) REFERENCES t_room(room_id)
ALTER TABLE t_guest ADD CONSTRAINT guest_fk_address_id FOREIGN KEY (address_id) REFERENCES t_address(address_id)
ALTER TABLE t_guest ADD CONSTRAINT guest_fk_card_id FOREIGN KEY (card_id) REFERENCES t_creditcard(card_id)
ALTER TABLE t_guest ADD CONSTRAINT guest_fk_hotel_id FOREIGN KEY (hotel_id) REFERENCES t_hotel(hotel_id)

ALTER TABLE t_guest_comments ADD CONSTRAINT comments_fk_guest_id FOREIGN KEY (guest_id) REFERENCES t_guest(guest_id)

ALTER TABLE t_wakeup ADD CONSTRAINT wakeup_fk_guest_id FOREIGN KEY (guest_id) REFERENCES t_guest(guest_id)

ALTER TABLE t_payment ADD CONSTRAINT payment_fk_client_id FOREIGN KEY (client_id) REFERENCES t_client(client_id)
ALTER TABLE t_payment ADD CONSTRAINT payment_fk_card_id FOREIGN KEY (card_id) REFERENCES t_creditcard(card_id)

ALTER TABLE t_address ADD CONSTRAINT address_fk_state FOREIGN KEY (state) REFERENCES t_tax(state)

ALTER TABLE t_user ADD CONSTRAINT user_fk_client_id FOREIGN KEY (client_id) REFERENCES t_client(client_id)
ALTER TABLE t_user ADD CONSTRAINT user_fk_role_id FOREIGN KEY (role_id) REFERENCES t_role(role_id)
ALTER TABLE t_user ADD CONSTRAINT user_fk_hotel_id FOREIGN KEY (hotel_id) REFERENCES t_hotel(hotel_id)

ALTER TABLE t_user_role ADD CONSTRAINT fk_role_id FOREIGN KEY (role_id) REFERENCES t_role(role_id)

ALTER TABLE t_lost_items ADD CONSTRAINT items_fk_hotel_id FOREIGN KEY (hotel_id) REFERENCES t_hotel(hotel_id)

ALTER TABLE t_invoice ADD CONSTRAINT invoice_fk_client_id FOREIGN KEY (client_id) REFERENCES t_client(client_id)
ALTER TABLE t_invoice ADD CONSTRAINT invoice_fk_card_id FOREIGN KEY (card_id) REFERENCES t_creditcard(card_id)

ALTER TABLE t_lost_items ADD CONSTRAINT lost_items_fk_user_id FOREIGN KEY (user_lost) REFERENCES t_user(user_id)
ALTER TABLE t_lost_items ADD CONSTRAINT lost_items_fk_user_id2 FOREIGN KEY (user_found) REFERENCES t_user(user_id)

alter table t_hotel add constraint ck_additional_occupant check (additional_occupant_cost >=0)
alter table t_hotel add constraint ck_late_check_out_cost check (late_checkout_cost >= 0)
alter table t_room add constraint ck_room_status check (status in('VACANT','NOTVACANT','DIRTY'))
alter table t_room add constraint ck_max_occupants check (max_occupants >= 0)
alter table t_hotel_room_rate add constraint ck_rate check (rate > 0)
alter table t_guest add constraint ck_occupants check (total_occupants > 0)
alter table t_guest add constraint ck_daily_rate check (daily_rate > 0)
alter table t_guest add constraint ck_reservation_start check (reservation_start_date >= GETDATE())
alter table t_guest_comments add constraint ck_type check (type in ('POS','NEU','NEG'))
alter table t_creditcard add constraint ck_number    check (len(number) between 1 and 17 and number not like '% %')
alter table creditcard add constraint ck_sec    check (security_code not like '% %')
alter table t_creditcard add constraint ck_yr   	 check (expiration_yr between convert(int,year(getdate())) and convert(int, year(getdate()))+10)
alter table t_creditcard add constraint ck_mth    check (expiration_mth between 1 and 12)
alter table [t_user] add constraint ck_user_id check (len(user_id) between 7 and 12 and user_id like '%[1-9]%' and user_id not like '% %')
alter table [t_user] add constraint ck_password check (len(user_id) between 7 and 12 and password like '%[1-9]%' and password not like '% %')
alter table [t_user] add constraint ck_email check (email like '%@%' and email not like '% %')
alter table t_service add constraint ck_max_hotel check (max_hotels > 0)
alter table t_service add constraint ck_room_cost check (room_cost > 0)
alter table t_service add constraint ck_tran_cost check (transaction_cost > 0)
alter table t_service add constraint ck_mly_service check (monthly_cost > 0)
alter table t_invoice add constraint ck_check_ins check (check_ins >= 0)
alter table t_invoice add constraint ck_check_outs check (check_outs >= 0)
alter table t_invoice add constraint ck_total_cost check (total_cost >= 0)

alter table t_room add constraint uc_room_name unique (hotel_id, room_name)

CREATE TABLE [dbo].[t_room_history](
    [history_id] [int] IDENTITY(1,1) NOT NULL,
    [user_id] varchar(12) NOT NULL,
    [room_id] int NOT NULL,
    [from_status] varchar(50) NOT NULL,
    [to_status] varchar(50) NOT NULL,
    [log_date_time] datetime
 CONSTRAINT [pk_history_id] PRIMARY KEY CLUSTERED )


CREATE TRIGGER [dbo].[clean_room_first]
   ON  [dbo].[t_room]
   AFTER UPDATE
AS
BEGIN
    --A room should never go from a NOTVACANT to VACANT. It must go into a DIRTY state first.
    --This trigger will ensure that the room status will follow this business rule.
    --VACANT --> NOTVACANT
    --NOTVACANT --> DIRTY
    --DIRTY-->VACANT
    
   		 declare @from varchar(50) = (select status from deleted)
   		 declare @to varchar(50) = (select status from inserted)
   		 
   		 --Don't worry if the room status stays the same, an update to the rooms attributes may cause this.
   		 if (@from = @to)
   			 begin
   				 return
   			 end
   		 else
   		 ---Make sure the business rules are followed.
   			 begin
   				 if (@from = 'VACANT' and @to <> 'NOTVACANT')
   				 or (@from = 'NOTVACANT' and @to <> 'DIRTY')
   				 or (@from = 'DIRTY' and @to <> 'VACANT')
   					 begin
   						 rollback transaction
   						 raiserror('Error: The room can''t be changed into an invalid status',16, 1)
   					 end
   			 end
END
