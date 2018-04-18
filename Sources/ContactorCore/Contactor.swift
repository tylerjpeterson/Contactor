//
//  Contactor.swift
//  Contactor
//
//  Created by Tyler Peterson on 04/18/18.
//  Copyright © 2018 Kettle. All rights reserved.
import Foundation
import Contacts

/// ContactRecord mutates CNContact instances into various output formats
struct ContactRecord: IterableProperties {

	/// Identifier
	var id: String! = ""

	/// Contact type (business vs individual)
	var type: String! = ""

	/// Contact name prefix
	var namePrefix: String! = ""

	/// Contact first name
	var givenName: String! = ""

	/// Contact middle name
	var middleName: String! = ""

	/// Contact last name
	var familyName: String! = ""

	/// Maiden name
	var previousFamilyName: String! = ""

	/// Suffix
	var nameSuffix: String! = ""

	/// Nickname
	var nickname: String! = ""

	/// Address
	var postalAddress: String! = ""

	/// Company
	var organization: String! = ""

	/// Department
	var department: String! = ""

	/// Title
	var jobTitle: String! = ""

	/// Birthday
	var birthday: String! = ""

	/// Notes
	var notes: String! = ""

	/// Pic image data
	var imageData: Data?

	/// Pic thumbnail image data
	var thumbnailImageData: Data?

	/// Pic data available
	var hasImageData: Bool! = false

	/// Collection of phone numbers
	var phoneNumbers: String! = ""

	/// Collection of email addresses
	var emailAddresses: String! = ""

	/// Collection of URLs
	var urlAddresses: String! = ""

	/// Collection of social profiles
	var socialProfiles: String! = ""

	/// Collection of IM addresses
	var instantMessageAddresses: String! = ""

	/// Base constructor for static prop retrieval
	init() {
	}

	/// Instantiate instance by passing CNContact instance
	///
	/// - Parameter payload: CNContact instance
	init(payload: CNContact) {
		self.id = payload.identifier
		self.type = payload.contactType.rawValue == 1 ? "Business" : "Individual"
		self.namePrefix = payload.namePrefix
		self.givenName = payload.givenName
		self.middleName = payload.middleName
		self.familyName = payload.familyName
		self.previousFamilyName = payload.previousFamilyName
		self.nameSuffix = payload.nameSuffix
		self.nickname = payload.nickname

		self.postalAddress = ""

		for row in payload.postalAddresses {
			if row.value.street.count > 0 && row.value.city.count > 0 && row.value.state.count > 0 && row.value.postalCode.count > 0 {
				self.postalAddress = "\n\(row.value.street)\n\(row.value.city), \(row.value.state) \(row.value.postalCode) \(row.value.country)"
			}
		}

		self.organization = payload.organizationName
		self.department = payload.departmentName
		self.jobTitle = payload.jobTitle

		if (payload.birthday != nil) {
			let f = DateFormatter()
			f.dateFormat = "MMMM d"
			self.birthday = f.string(from: (payload.birthday?.date!)!)
		}

		self.notes = payload.note
		self.hasImageData = payload.imageDataAvailable

		if self.hasImageData {
			self.imageData = payload.imageData
			self.thumbnailImageData = payload.thumbnailImageData
		}

		self.phoneNumbers = "\n"
		self.emailAddresses = "\n"
		self.urlAddresses = "\n"
		self.socialProfiles = "\n"
		self.instantMessageAddresses = "\n"

		for num in payload.phoneNumbers {
			self.phoneNumbers = self.phoneNumbers + "\(num.label?.description ?? ""): \(num.value.stringValue)\n"
		}

		for num in payload.emailAddresses {
			self.emailAddresses = self.emailAddresses + "\(num.label?.description ?? ""): \(num.value)\n"
		}

		for num in payload.urlAddresses {
			self.urlAddresses = self.urlAddresses + "\(num.label?.description ?? ""): \(num.value)\n"
		}

		for num in payload.socialProfiles {
			self.socialProfiles = self.socialProfiles + "\(num.label?.description ?? ""): \(num.value)\n"
		}

		for num in payload.instantMessageAddresses {
			self.instantMessageAddresses = self.instantMessageAddresses + "\(num.value.username)\n"
		}
	}

	/// Converts a contact's properties to a string
	///
	/// - Returns: Properties as string
	func contactToString() -> String {
		var output: String = ""

		do {
			let props = try self.allProperties()

			for prop in props {
				let outputValue = (prop.value as! String)
					.replacingOccurrences(of: "_$!<", with: "")
					.replacingOccurrences(of: ">!$_", with: "")

				output += prop.key
				output += ": "
				output += outputValue
				output += "\n"
				output = output.replacingOccurrences(of: "\n\n", with: "\n")
			}
		} catch _ {
		}

		return output
	}

	/// Returns instance properties as a CSV row
	///
	/// - Returns: String CSV row of properties
	func contactToCSV() -> String {
		var row: [String] = []

		do {
			let props = try self.allProperties()

			for prop in props {
				let outputValue = (prop.value as! String)
					.replacingOccurrences(of: "_$!<", with: "")
					.replacingOccurrences(of: ">!$_", with: "")
					.trimmingCharacters(in: .whitespacesAndNewlines)

				row.append(outputValue)
			}
		} catch _ {
		}

		return "\"" + row.joined(separator: "\",\"") + "\""
	}

	/// Returns property keys for use as a CSV header row
	///
	/// - Returns: String of properties as CSV header
	static func CSVHeader() -> String {
		var row: [String] = []

		do {
			let props = try ContactRecord().allProperties()
			for prop in props {
				row.append(prop.key)
			}
		} catch _ {
		}

		return "\"" + row.joined(separator: "\",\"") + "\""
	}
}

/// Provides a simplified API to search contacts, determine their existence, and create new contacts via Apple's Contacts framework.
///
/// - Requires: Apple Contacts Framework - `import Contacts`
/// - SeeAlso: [Contacts Framework documentation](https://developer.apple.com/documentation/contacts)
public class Contactor {

	/// Reference to local CNContactStore instance
	let store: CNContactStore = CNContactStore()

	/// Flag set to record whether or not access to contacts has been granted
	var hasPermission: Bool = false

	/// Initializes a new Contactor instance
	public init() {
		store.requestAccess(for: CNEntityType.contacts) {granted, error in
			if (error != nil) {
				print(error!.localizedDescription)
				exit(0)
			} else if !granted {
				print("Access denied.")
				exit(0)
			} else {
				self.hasPermission = true
			}
		}
	}

	/// Search user contacts against a filter, and optionally export the results as a collection of VCFs
	///
	/// - Parameters:
	///   - filter: The string to filter contact names against
	///   - output: Directory to write output files to
	///   - format: Format of returned results
	/// - Returns: String value representing found contacts in the requested format
	public func searchContacts(filter: String = "*", output: String? = nil, format: String = "text", completion: @escaping (_ results: String) -> Void) {
		self.getContacts(matching: filter) {(result: [CNContact]?) in
			var outputString: String = ""

			/// Output data line by line directly to stdout
			if format == "text" {
				outputString += "Found \(result?.count ?? 0) contacts matching \"\(filter)\":\n\n"

				for contact in result! {
					let foundContact = ContactRecord(payload: contact)
					outputString += foundContact.contactToString() + "\n"
				}

				completion(outputString)

			/// Write output to a VCF file in the passed directory (output parameter)
			} else if format == "file" {
				var dir: URL!

				if output == nil {
					dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
				} else {
					dir = URL.init(fileURLWithPath: output!)
				}

				for contact in result! {
					var fileURL = dir.appendingPathComponent("\(contact.givenName) \(contact.familyName).vcf")

					if fileURL.lastPathComponent == " .vcf" {
						fileURL = dir.appendingPathComponent("\(contact.identifier).vcf")
					}

					do {
						try CNContactVCardSerialization
							.data(jpegPhotoContacts: [contact])
							.write(to: fileURL, options: [Data.WritingOptions.atomic])
					} catch let error {
						print(error)
					}
				}

				completion("\(result?.count ?? 0) VCF file(s) written to \(dir.path)")

			/// Write output as VCF data to stdout (easily create an aggregate VCF by piping output)
			} else if format == "vcf" {
				for contact in result! {
					do {
						let data = try CNContactVCardSerialization.data(jpegPhotoContacts: [contact])
						outputString += String(data: data, encoding: .utf8)! + "\n"
					} catch {}
				}

				completion(outputString)

			/// Write output to CSV format, written to stdout
			} else {
				outputString += ContactRecord.CSVHeader() + "\n"

				for contact in result! {
					let foundContact = ContactRecord(payload: contact)
					outputString += foundContact.contactToCSV() + "\n"
				}

				completion(outputString)
			}
		}
	}

	/// Determines if and how many contacts match the passed search criteria, writing the number of matches to stdout
	///
	/// - Parameter filter: The string to filter contact names against
	public func contactExists(filter: String, completion: @escaping (_ results: Int) -> Void) {
		self.getContacts(matching: filter) {(result: [CNContact]?) in
			completion(result?.count ?? 0)
		}
	}

	/// Adds a contact to the user's default contact group
	///
	/// - Parameter contact: Dictionary of properties and values used to create the contact
	public func addContact(contact: [String: String], completion: @escaping (_ createdContact: CNMutableContact?) -> Void) {
		let saveRequest = CNSaveRequest()
		let newContact = CNMutableContact()
		let homeAddress = CNMutablePostalAddress()
		let birthday = NSDateComponents()
		let emailAddresses = contact["email"]?.components(separatedBy: ",") ?? [""]
		let phoneNumbers = contact["phone"]?.components(separatedBy: ",") ?? [""]

		var emails: [CNLabeledValue<NSString>] = []
		var numbers: [CNLabeledValue<CNPhoneNumber>] = []

		for email in emailAddresses {
			emails.append(CNLabeledValue(
				label: CNLabelHome,
				value: NSString.init(string: email)))
		}

		for number in phoneNumbers {
			numbers.append(CNLabeledValue(
				label: CNLabelPhoneNumberiPhone,
				value: CNPhoneNumber(stringValue: number)))
		}

		newContact.givenName = contact["first"]!
		newContact.familyName = contact["last"]!
		newContact.emailAddresses = emails
		newContact.phoneNumbers = numbers
		homeAddress.street = contact["street"]!
		homeAddress.city = contact["city"]!
		homeAddress.state = contact["state"]!
		homeAddress.postalCode = contact["zip"]!
		newContact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: homeAddress)]

		if contact["birthday"] != "" && contact["birthmonth"] != "" {
			birthday.day = Int(contact["birthday"]!)!
			birthday.month = Int(contact["birthmonth"]!)!
			newContact.birthday = birthday as DateComponents
		}

		if contact["pic"] != "" {
			let data = NSData(contentsOfFile: contact["pic"]!)
			newContact.imageData = data! as Data
		}

		saveRequest.add(newContact, toContainerWithIdentifier: nil)

		do {
			try self.store.execute(saveRequest)

			completion(newContact)
		} catch {
			print("Error storing contact: \(error)")

			completion(nil)
		}
	}

	/// Remove a contact based on its identifier
	///
	/// - Parameters:
	///   - id: Identifier of contact to be removed
	///   - completion: Completion handler passed true on success, false on failure
	public func removeContact(id: String, completion: @escaping (_ result: Bool) -> Void) {
		let keysToFetch: [CNKeyDescriptor] = [
			CNContactImageDataKey as CNKeyDescriptor,
			CNContactVCardSerialization.descriptorForRequiredKeys()
		]

		do {
			let request: CNSaveRequest = CNSaveRequest()
			let identifierPredicate: NSPredicate = CNContact.predicateForContacts(withIdentifiers: [id])
			let contacts: [CNContact] = try store.unifiedContacts(matching: identifierPredicate, keysToFetch: keysToFetch)
			let contact: CNContact! = contacts.first
			let mutable: CNMutableContact = contact.mutableCopy() as! CNMutableContact

			request.delete(mutable)
			try self.store.execute(request)
			completion(true)
		} catch {
			print("Error removing contact: \(error)")
			completion(false)
		}
	}

	/// Internal method to search contacts filtering against passed parameters, and optionally exporting results to VCF
	///
	/// - Parameters:
	///   - matching: The string to filter contact names against
	///   - completion: Callback fired upon retrieval (and optional export) of contacts
	private func getContacts(matching: String, completion: @escaping (_ result: [CNContact]) -> Void) {
		let namePredicate: NSPredicate = CNContact.predicateForContacts(matchingName: matching)
		let identifierPredicate: NSPredicate = CNContact.predicateForContacts(withIdentifiers: [matching])

		let keysToFetch: [CNKeyDescriptor] = [
			CNContactImageDataKey as CNKeyDescriptor,
			CNContactVCardSerialization.descriptorForRequiredKeys()
		]

		do {
			var contacts: [CNContact] = try store.unifiedContacts(matching: namePredicate, keysToFetch: keysToFetch)

			if contacts.count < 1 {
				contacts = try store.unifiedContacts(matching: identifierPredicate, keysToFetch: keysToFetch)
			}

			completion(contacts)
		} catch let error as NSError {
			print(error.localizedDescription)
		}
	}

	/// Internal method to save a contact as a VCF
	///
	/// - Parameter contacts: Collection of contacts to export
	private func saveVcfs(contacts: [CNContact]) {
		for contact in contacts {
			if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
				let fileURL = dir.appendingPathComponent("\(contact.givenName) \(contact.familyName).vcf")
				do {
					try CNContactVCardSerialization
						.data(jpegPhotoContacts: [contact])
						.write(to: fileURL, options: [Data.WritingOptions.atomic])
				} catch let error {
					dump(error)
				}
			}
		}
	}
}

// MARK: - Protocols

/// Retrieve all properties in a struct
protocol IterableProperties {
	/// Retrieve a dictionary of all properties
	///
	/// - Returns: Dictionary of properties/values
	/// - Throws: Error
	func allProperties() throws -> [String: Any]
}

// MARK: - Extensions

/// VCF serialization
extension CNContactVCardSerialization {

	/// Retrieves vCard data for a given contact with the contact photo appended
	///
	/// - Parameters:
	///   - vcard: vcard data of target contact
	///   - photo: photo to be added to vCard
	/// - Returns: vCard data
	internal class func vcardDataAppendingPhoto(vcard: Data, photoAsBase64String photo: String) -> Data? {
		let vcardAsString = String(data: vcard, encoding: .utf8)
		let vcardPhoto = "PHOTO;TYPE=JPEG;ENCODING=BASE64:".appending(photo)
		let vcardPhotoThenEnd = vcardPhoto.appending("\nEND:VCARD")

		if let vcardPhotoAppended = vcardAsString?.replacingOccurrences(of: "END:VCARD", with: vcardPhotoThenEnd) {
			return vcardPhotoAppended.data(using: .utf8)
		}

		return nil
	}

	/// Base-64 encode a contact image when contact data is written to a file
	///
	/// - Parameter jpegPhotoContacts: Collection of CNContact instances to export
	/// - Returns: VCF data with or without the encoded contact image included
	/// - Throws: Error
	class func data(jpegPhotoContacts: [CNContact]) throws -> Data {
		var overallData = Data()

		for contact in jpegPhotoContacts {
			let data = try CNContactVCardSerialization.data(with: [contact])

			if contact.imageData != nil {
				if let base64imageString = contact.imageData?.base64EncodedString(),
					let updatedData = vcardDataAppendingPhoto(vcard: data, photoAsBase64String: base64imageString) {
					overallData.append(updatedData)
				}
			} else {
				overallData.append(data)
			}
		}
		return overallData
	}
}

/// Extension to loop properties
extension IterableProperties {

	/// Retrieves a dict of all properties and values
	///
	/// - Returns: Dictionary of properties and their values
	/// - Throws: Error
	func allProperties() throws -> [String: Any] {
		var result: [String: String] = [:]
		let mirror = Mirror(reflecting: self)

		guard let
			style = mirror.displayStyle,
			style == .struct ||
				style == .class else {
					throw NSError(domain: "hris.to", code: 777, userInfo: nil)
		}

		for (labelMaybe, valueMaybe) in mirror.children {
			guard let label = labelMaybe else {
				continue
			}

			if let val = valueMaybe as? NSString {
				result[label] = String.init(val)
			}
		}

		return result
	}
}
