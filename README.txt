Student Name: Evangelos Poneres
Semester: Fall 2013
Case Study Title: A Vendors Perspective on Database Design
Advisor Name: Harry Shasho
Abstract: 
		An up-and-coming software firm, Vango’s Software Co. (VSO), is aiming to enter 
	the cloud computing market. They intend on developing a Hotel Management System (HMS) 
	SaaS solution called KsenoCloud. SaaS solutions tend to have lower operational costs 
	associated with them, so VSO plans to market their product to small/mid-size hoteliers 
	which may not be able to afford implementing and maintaining an on-premise HMS, but 
	still want the benefits a HMS can provide. 
		Evangelos Poneres (Sr. Database Administrator) has been tasked with gathering 
	the necessary requirements to design a database that can fulfill the VSO venture 
	as well as designing the database itself. Since this will be VSO first time offering 
	a cloud technology, Mr. Poneres must take into account various data architectures, 
	and use the one most suitable from a systems perspective and their future hotelier 
	customers. The system will have to function just as an on-premise HMS would, but 
	it will be available via a web interface to multiple clients (hoteliers). 

RDMS: Microsoft SQL Server

Narrative:
		This project is based on the business model that a typical hotel and applying 
	it to a software-as-a-service model. The system being developed would be designed 
	to cater to business owners that may own one or more hotels (clients). Each client 
	may subscribe to the system as which point they would be entering a 
	service-level-agreement (SLA) with the systems vendor. With regard to the systems 
	technical aspects, the SLA specifies how the client will be charged based on their 
	system usage. The price associated to system usage can be derived using the formula 
	below.
			Monthly $ = Flat Mly Rate($) + 
						((tot. Chk-ins + tot. Chk-outs)*Transaction fee) +
							(total Rooms * Room fee)
		The Flat Monthly Rate, Transaction Fee, and Room Fee is dependent on the service 
	plan that the client chose during registration. The client may change their plan at 
	any time and an pro-rated invoice will be generated at that time.
		Once a client is registered as a subscriber, they may begin to create hotels, and 
	rooms for their hotels within the system; in addition, they may create user accounts 
	for their employees at each hotel so that they may check-in/check-out guests at each 
	hotel. The multi-tenant design of the database allows multiple clients to utilize the 
	same system, but still receive a customized experience. 
		At the moment, there are few customizable features that can vary from one client 
		to another:
		
		*	Each hotel may have its own check-in deadline for guests that decided to 
			reserve a room and did not call ahead to cancel their reservation. Once 
			the deadline is met, they will be charged for one nights stay
		*	Each hotel may have its own check-out deadline for guests that decide to 
			sleep-in. Once the deadline is met, they will be charged a fee that is 
			set by the client.
		*	Each Client may create rate “buckets” for the rooms at their hotel which 
			allows them adjust room prices efficiently. Client may follow any desired 
			naming convention for their rooms.
				
		Guest may be checked into and out of any particular room at a given hotel. As the 
	rooms are used, their status will follow a cycle: VACANT-->NOTVACANT-->DIRTY; this 
	enforces the hotel employees to make sure the room is cleaned between each stay. 
	Guests also have the ability to reserve rooms in advance. When available rooms are 
	searched using a particular date range, reserved rooms and vacant rooms will appear 
	in the system. This tells the employee that the guest might have reserved a room 
	and they may check into a reserved room if they supply the same credit-card or 
	drivers license that was used to make the reservation. Upon check-out, an invoice 
	will be generated for the guest; the employee performing the check-out has the 
	option of removing any additional fees. When the invoice is generated, the hotels 
	address will be used for tax purposes; a breakdown of the guests charges will be 
	listed on the invoice as well as information about the hotel (name, address).
		Client will have access to a reporting dashboard with will give them statistical 
	information about their hotel's revenue. This information will be useful when they 
	take care of finances outside of this system. In addition, guests will have the 
	option of making comments about their stay during check-out; these comments will be 
	available directly to the clients so they can assess where improvements in service 
	can be made within their hotels.