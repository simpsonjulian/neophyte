package issuemigrator

import groovyx.net.http.HttpResponseException

/*
 * Copyright (C) 2012 Neo Technology
 * All rights reserved
 */
class Main {
    public static void main(String[] args) {
        if (args.length < 4) throw new IllegalArgumentException("Usage: issuemigrator <destination user> <destination> <username> <password> <repositories>")

        def destinationUser = args[0]
        def destination = args[1]
        def username = args[2]
        def password = args[3]
        def repositories = args.length == 5 ? args[4] : "community advanced enterprise manual packaging python-embedded cypher-plugin gremlin-plugin parents testing-utils"

        try {
            new IssueMigrator(destinationUser, destination, username, password).migrateIssues(repositories.split(" "))
        } catch (HttpResponseException e) {
            println e.response.status
            println e.response.data
            throw e
        }
    }
}
