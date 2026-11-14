# Volunteering vocabulary inference rules
#
# Rules that OWL cannot express for the OWL Micro reasoner Fuseki uses
# (class-conditioned sub-properties, owl:sameAs).
# Applied to the data as SPARQL Update when the knowledge graph is built,
# so that inferred triples are also full-text indexed.

PREFIX :                <https://ns.volunteeringdata.io/>
PREFIX owl:             <http://www.w3.org/2002/07/owl#>


# An activity that has a title has that title as its activity title.
INSERT { ?activity :activityTitle ?title . }
WHERE {
    ?activity
        a :Activity ;
        :title ?title ;
    .
} ;

# An organisation that has a name has that name as its organisation name.
INSERT { ?organisation :organisationName ?name . }
WHERE {
    ?organisation
        a :Organisation ;
        :name ?name ;
    .
} ;

# An organisation that has an activity has it as an organisation activity.
# (The ontology's owl:inverseOf then gives :activityOrganisation and :organisation.)
INSERT { ?organisation :organisationActivity ?activity . }
WHERE {
    ?organisation
        a :Organisation ;
        :activity ?activity ;
    .
} ;

# Anything said about a resource declared owl:sameAs one of ours is also said about ours,
# e.g. a session located in https://data.volunteer.scot/Geography/LocalAuthority/Edinburgh
# is located in :Edinburgh.
INSERT { ?subject ?predicate ?ours . }
WHERE {
    ?ours owl:sameAs ?other .
    FILTER(STRSTARTS(STR(?ours), STR(:)))

    ?subject ?predicate ?other .
    FILTER(?predicate != owl:sameAs)
}
