package issuemigrator

import groovyx.net.http.HttpResponseException

/*
 * Copyright (C) 2012 Neo Technology
 * All rights reserved
 */
class Main
{
    public static void main( String[] args )
    {
        try {
            new IssueMigrator( args[0], args[1], args[2] ).migrateIssues()
        } catch (HttpResponseException e) {
            println e.response.status
            println e.response.data
            throw e
        }
    }
}
