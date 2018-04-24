//
//  main.swift
//  Contacter
//
//  Created by Tyler Peterson on 04/18/18.
//  Copyright © 2018 Kettle. All rights reserved.
import SwiftCLI
import ContactorCore

/// Create an instance of ContactorCore
let contacts = Contactor()

/// Create an instance of SwiftCLI
let cli = CLI(
	name: "Contactor",
	version: "1.0.2",
	description: "Contactor - manage contacts via the command line"
)

/// Search command - searches contacts against provided criteria with an option to export all results to VCF files
class SearchCommand: Command {

	/// Name of command
	let name = "search"

	/// Search command's short description
	let shortDescription = "Search contacts by name"

	/// Dir output option
	let output = Key<String>("-o", "--output", description: "Write individual VCF files to directory <value>")

	/// Deep output option
	let deep = Flag("-d", "--deep", description: "Perform a deep search (search against all contact properties)")

	/// Text output option
	let str = Flag("-t", "--text", description: "Write output to stdout as text (default)")

	/// CSV output option
	let csv = Flag("-c", "--csv", description: "Write output to stdout in CSV format")

	/// VCF output option
	let vcf = Flag("-v", "--vcf", description: "Write output to stdout in VCF format")

	/// Enforcing option group restrictions
	var optionGroups: [OptionGroup] {
		return [OptionGroup(options: [output, str, csv, vcf], restriction: .atMostOne)]
	}

	/// Search command parameters
	let search = Parameter()

	/// Passes command instructions as options to the ContactorCore instance
	///
	/// - Throws: Error
	func execute() throws {
		let deepSearch = self.deep.value ? true : false
		var outputDir: String? = nil
		var format: String = "text"

		if (output.value != nil) {
			outputDir = output.value
			format = "file"
		} else if csv.value {
			format = "csv"
		} else if vcf.value {
			format = "vcf"
		}

		contacts.searchContacts(filter: search.value, deepSearch: deepSearch, output: outputDir, format: format, completion: { results in
			self.stdout <<< results
		})
	}
}

/// Search command - searches contacts against provided criteria with an option to export all results to VCF files
class ListCommand: Command {

	/// Name of command
	let name = "list"

	/// Seach command's short description
	let shortDescription = "List all contacts"

	/// File output option
	let output = Key<String>("-o", "--output", description: "Write individual VCF files to directory <value>")

	/// Text output option
	let str = Flag("-t", "--text", description: "Write output to stdout as text (default)")

	/// CSV output option
	let csv = Flag("-c", "--csv", description: "Write output to stdout in CSV format")

	/// VCF output option
	let vcf = Flag("-v", "--vcf", description: "Write output to stdout in VCF format")

	/// Enforcing option group restrictions
	var optionGroups: [OptionGroup] {
		return [OptionGroup(options: [output, str, csv, vcf], restriction: .atMostOne)]
	}

	/// Passes command instructions as options to the ContactorCore instance
	///
	/// - Throws: Error
	func execute() throws {
		var outputDir: String? = nil
		var format: String = "text"

		if (output.value != nil) {
			outputDir = output.value
			format = "file"
		} else if csv.value {
			format = "csv"
		} else if vcf.value {
			format = "vcf"
		}

		contacts.searchContacts(output: outputDir, format: format, completion: { results in
			self.stdout <<< results
		})
	}
}

/// Exists command - checks to see if a contact matching provided criteria exists
class ExistsCommand: Command {

	/// Name of command
	let name = "exists"

	/// Exist command's short description
	let shortDescription = "Check if contact exists"

	/// Deep output option
	let deep = Flag("-d", "--deep", description: "Perform a deep search (search against all contact properties)")

	/// Exists command parameters
	let search = Parameter()

	/// Passes command instructions as options to the ContactorCore instance
	///
	/// - Throws: Error
	func execute() throws {
		contacts.contactExists(filter: search.value, deepSearch: deep.value, completion: { results in
			self.stdout <<< "\(results)"
		})
	}
}

/// Remove command - removes a contact based on its identifier
class RemoveCommand: Command {

	/// Name of command
	let name = "remove"

	/// Exist command's short description
	let shortDescription = "Remove a contact"

	/// Exists command parameters
	let identifier = Parameter()

	/// Passes command instructions as options to the ContactorCore instance
	///
	/// - Throws: Error
	func execute() throws {
		contacts.removeContact(id: self.identifier.value, completion: { success in
			if success == true {
				print("Contact with identifier \(self.identifier.value) successfully removed.")
			} else {
				print("Contact with identifier \(self.identifier.value) could not be removed.")
			}
		})
	}
}

/// Add command - creates and adds a new contact
class AddCommand: Command {

	/// Name of command
	let name = "add"

	/// Add command's short description
	let shortDescription = "Add a contact"

	/// Contact's first name
	let first = Key<String>("-f", "--first", description: "Contact first name")

	/// Contact's last name
	let last = Key<String>("-l", "--last", description: "Contact last name")

	/// Contact's street address
	let street = Key<String>("-a", "--street", description: "Contact street address")

	/// Contact's city
	let city = Key<String>("-c", "--city", description: "Contact city")

	/// Contact's state
	let state = Key<String>("-s", "--state", description: "Contact state")

	/// Contact's zip code
	let zip = Key<String>("-z", "--zip", description: "Contact zip code")

	/// Contact's telephone number
	let telephone = Key<String>("-t", "--telephone", description: "Phone numbers (seperated by ',')")

	/// Contact's email address (separate multiple addresses with a comma)
	let email = Key<String>("-e", "--email", description: "Email addresses (separated by ',')")

	/// Path to an image of the contact
	let pic = Key<String>("-p", "--pic", description: "Contact photo")

	/// Contact's day of birth
	let birthday = Key<String>("-b", "--birthday", description: "Contact birth day")

	/// Contact's month of birth
	let birthmonth = Key<String>("-m", "--birthmonth", description: "Contact birth month")

	/// Contact's company
	let company = Key<String>("-o", "--company", description: "Contact's company")

	/// Contact's title
	let title = Key<String>("-i", "--title", description: "Contact's title")

	/// Requires command is provided with at least a first or last name for the new contact
	var optionGroups: [OptionGroup] {
		return [OptionGroup(options: [first, last], restriction: .atLeastOne)]
	}

	/// Passes command instructions to the ContactorCore instance, adding the newly created contact to the user's contacts
	///
	/// - Throws: Error
	func execute() throws {

		/// New contact's properties collection
		var contactProps = [String: String]()
		contactProps["first"] = first.value ?? ""
		contactProps["last"] = last.value ?? ""
		contactProps["street"] = street.value ?? ""
		contactProps["city"] = city.value ?? ""
		contactProps["state"] = state.value ?? ""
		contactProps["zip"] = zip.value ?? ""
		contactProps["phone"] = telephone.value ?? ""
		contactProps["email"] = email.value ?? ""
		contactProps["pic"] = pic.value ?? ""
		contactProps["birthday"] = birthday.value ?? ""
		contactProps["birthmonth"] = birthmonth.value ?? ""
		contactProps["company"] = company.value ?? ""
		contactProps["title"] = title.value ?? ""

		contacts.addContact(contact: contactProps, completion: { newContactIdentifier in
			if newContactIdentifier != nil {
				contacts.searchContacts(filter: newContactIdentifier!, format: "text", completion: { result in
					self.stdout <<< result
				})
			} else {
				print("New contact was not created.")
			}
		})
	}
}

cli.commands = [
	AddCommand(),
	ListCommand(),
	ExistsCommand(),
	SearchCommand(),
	RemoveCommand()
]

cli.goAndExit()
