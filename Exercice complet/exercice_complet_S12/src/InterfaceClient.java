import java.sql.*;
import java.util.Scanner;

public class InterfaceClient {

    String url = "jdbc:postgresql://localhost:****/******"; // TODO : url connection
    private final Scanner scanner = new Scanner(System.in);
    Connection conn = null;
    private PreparedStatement inscrireClient;
    private PreparedStatement listeEventsParSalle;
    private PreparedStatement ajouterReservation;
    private PreparedStatement listeReservations;
    private PreparedStatement listeFutursFestivals;
    private PreparedStatement listeEventsParArtiste;
    private Integer identifiantClient;


    public InterfaceClient() {
        try {
            Class.forName("org.postgresql.Driver");

        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            conn = DriverManager.getConnection(url, "", ""); // TODO: fill in user & password
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }

        try {
            inscrireClient = conn.prepareStatement("SELECT gestion_evenements.inscrireClient(?, ?, ?)");
            listeEventsParSalle = conn.prepareStatement("SELECT * FROM gestion_evenements.evenementsParSalle WHERE id_salle_event = ?");
            ajouterReservation = conn.prepareStatement("SELECT gestion_evenements.ajouterReservation(?, ?, ?, ?)");
            listeReservations = conn.prepareStatement("SELECT * FROM gestion_evenements.reservationsClients WHERE client = ?");
            listeFutursFestivals = conn.prepareStatement("SELECT * FROM gestion_evenements.festivalView");
            listeEventsParArtiste = conn.prepareStatement("SELECT * FROM gestion_evenements.evenementsParArtiste WHERE artistes LIKE ?");

        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    private boolean choixMenu(String choix) {
        try {
            Integer.parseInt(choix);
            return false;
        } catch (NumberFormatException e) {
            return true;
        }
    }

    public void lancerMenu() {
        String tmp_choix;

        int choix;
        do {
            System.out.println("\n1 => Se connecter");
            System.out.println("2 => S'inscrire\n");

            System.out.print("Veuillez introduire votre choix : ");
            tmp_choix = scanner.next();

            while (choixMenu(tmp_choix)) {
                System.out.println("Votre choix n'est pas un chiffre compris entre 1 et 2\nVeuillez introduire votre choix : ");
                tmp_choix = scanner.next();
                scanner.nextLine();
            }
            choix = Integer.parseInt(tmp_choix);

            switch (choix) {
                case 1:
                    connecterClient();
                    break;
                case 2:
                    inscrireClient();
                    break;
            }
        } while (choix < 1 || choix > 2);

        System.out.println("\n************************************************************** BIENVENUE DANS L'INTERFACE CLIENT ! *********************************************************************\n");
        do {
            System.out.println("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ MENU +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
            System.out.println("1 => Voir les événements d’une salle particulière triés par date");
            System.out.println("2 => Voir ses réservations");
            System.out.println("3 => Voir les festivals futurs");
            System.out.println("4 => Voir les événements auxquels participe un artiste particulier triés par date");
            System.out.println("5 => Se déconnecter\n");

            System.out.print("Veuillez introduire votre choix : ");
            tmp_choix = scanner.next();
            scanner.nextLine();

            while (choixMenu(tmp_choix)) {
                System.out.print("Votre choix n'est pas un chiffre compris entre 1 et 5\nVeuillez introduire votre choix : ");
                tmp_choix = scanner.next();
                scanner.nextLine();
            }
            choix = Integer.parseInt(tmp_choix);

            switch (choix) {
                case 1:
                    voirEventsParSalle();
                    menuReservation();
                    break;
                case 2:
                    voirSesReservations();
                    break;
                case 3:
                    voirFutursFestivals();
                    break;
                case 4:
                    voirEventsParArtiste();
                    break;
                case 5:
                    seDeconnecter();
                    break;
            }
        } while (choix >= 1 && choix <= 5);

        System.out.println("Fin du programme");
        close();
    }

    private boolean connexionClient(String email_address, String password) {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT gestion_evenements.recupMDPCrypte(?)");
            ps.setString(1, email_address);
            ps.execute();
            ResultSet result = ps.getResultSet();
            if (result.next() && BCrypt.checkpw(password, result.getString(1))) {
                System.out.println("L'authentification est réussie");
                PreparedStatement id = conn.prepareStatement("SELECT id_client FROM gestion_evenements.clients WHERE email = ?");
                id.setString(1, email_address);
                id.execute();
                ResultSet idResult = id.getResultSet();

                if (idResult.next()) {
                    identifiantClient = idResult.getInt("id_client");
                    return true;
                }
            } else {
                System.out.println("Votre mot de passe est incorrect !");
                return false;
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage() + "\n");
            return false;
        }
        return false;
    }

    private boolean inscriptionClient(String username, String email_address, String password) {
        try {
            String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt()); // Hâchage du mot de passe

            inscrireClient.setString(1, username);
            inscrireClient.setString(2, email_address);
            inscrireClient.setString(3, hashedPassword);

            inscrireClient.executeQuery();

            System.out.println("\nInscription réussie !\n");
            return true;

        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return false;
        }
    }

    private void inscrireClient() {
        System.out.println("\nVeuillez encoder... ");
        System.out.println("\nVeuillez encoder... ");
        String username;
        String email_add;
        String mdp;

        do {
            System.out.print("Votre nom d'utilisateur : ");
            username = scanner.next();
            System.out.print("Votre adresse email : ");
            email_add = scanner.next();
            System.out.print("Votre mot de passe : ");
            mdp = scanner.next();

        } while (!inscriptionClient(username, email_add, mdp));
    }

    public void connecterClient() {
        String adresse_mail;
        String mdp;
        do {
            System.out.print("\nVeuillez entrer votre adresse email : ");
            adresse_mail = scanner.next();
            System.out.print("Veuillez entrer votre mot de passe : ");
            mdp = scanner.next();
        } while (!connexionClient(adresse_mail, mdp));
    }

    private void voirEventsParSalle() {
        System.out.print("Veuillez entrer le numéro de salle : ");
        int idSalle = scanner.nextInt();

        try {
            listeEventsParSalle.setInt(1, idSalle);
            try (ResultSet rs = listeEventsParSalle.executeQuery()) {
                while (rs.next()) {
                    System.out.println("\nNom de l'évènement : " + rs.getString(1));
                    System.out.println("Date de l'évènement : " + rs.getString(2));
                    System.out.println("Nom de la salle de l'évènement : " + rs.getString(4));
                    System.out.println("Artistes : " + rs.getString(5));
                    System.out.println("Prix : " + rs.getString(6));
                    System.out.println("Complet : " + (rs.getBoolean(7) ? "Oui\n" : "Non\n"));
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    private void voirSesReservations() {
        try {
            listeReservations.setInt(1, identifiantClient);
            try (ResultSet rs = listeReservations.executeQuery()) {
                while (rs.next()) {
                    System.out.println("\nNom de l'évènement : " + rs.getString(1));
                    System.out.println("Date de l'évènement : " + rs.getString(2));
                    System.out.println("Numéro de réservation : " + rs.getString(3));
                    System.out.println("Nombre de tickets : " + rs.getString(5));
                    System.out.println();
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    private void voirFutursFestivals() {
        try (ResultSet rs = listeFutursFestivals.executeQuery()) {
            while (rs.next()) {
                System.out.println("\nIdentifiant du festival : " + rs.getString(1));
                System.out.println("Nom du festival : " + rs.getString(2));
                System.out.println("Date de début : " + rs.getString(3));
                System.out.println("Date de fin : " + rs.getString(4));
                System.out.println("Prix total : " + rs.getString(5));
                System.out.println();
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    private void voirEventsParArtiste() {
        System.out.print("Veuillez entrer le nom de l'artiste : ");
        String nomArtiste = scanner.next();

        try {
            listeEventsParArtiste.setString(1, "%" + nomArtiste + "%");
            try (ResultSet rs = listeEventsParArtiste.executeQuery()) {
                while (rs.next()) {
                    System.out.println("\nNom de l'évènement : " + rs.getString(1));
                    System.out.println("Date de l'évènement : " + rs.getString(2));
                    System.out.println("Identifiant de la salle : " + rs.getString(3));
                    System.out.println("Nom de la salle : " + rs.getString(4));
                    System.out.println("Artistes : " + rs.getString(5));
                    System.out.println("Prix : " + rs.getString(6));
                    System.out.println("Complet : " + (rs.getBoolean(7) ? "Oui\n" : "Non\n"));
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    private void menuReservation() {
        String choice = "";

        while (!choice.equals("o") && !choice.equals("O")) {
            System.out.println("Souhaitez-vous réserver des tickets pour un évènement? (o/n)");
            choice = scanner.next();

            if (choice.equals("o") || choice.equals("O")) {
                System.out.println("\n-------------------- RESERVATION --------------------");
                int idSalle;
                String dateEvent;
                int nombreTickets;

                do {
                    System.out.println("Veuillez entrer l'id de la salle : ");
                    idSalle = scanner.nextInt();
                    System.out.println("Veuillez entrer la date de l'évènement : ");
                    dateEvent = scanner.next();
                    System.out.println("Veuillez entrer le nombre de tickets souhaité : ");
                    nombreTickets = scanner.nextInt();

                } while (!ajouterReservation(idSalle, dateEvent, nombreTickets));
            } else if (choice.equals("n") || choice.equals("N")) break;

            System.out.print("Entrée invalide, réessayez. ");
        }
    }

    private boolean ajouterReservation(int venue_id, String event_date, int ticket_qty) {
        try {
            try {
                ajouterReservation.setInt(1, venue_id);
                ajouterReservation.setDate(2, Date.valueOf(event_date));
                ajouterReservation.setInt(3, ticket_qty);
                ajouterReservation.setInt(4, identifiantClient);

                ajouterReservation.executeQuery();

                System.out.println("\nRéservation effectuée !\n");
                return true;
            } catch (IllegalArgumentException e) {
                System.out.println("\nVeuillez respecter le format YYYY-MM-DD.\n");
                return false;
            }

        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return false;
        }
    }

    private void seDeconnecter() {
        identifiantClient = null;
        lancerMenu();
    }

    private void close() {
        try {
            conn.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    public static void main(String[] args) {
        InterfaceClient interfaceClient = new InterfaceClient();
        interfaceClient.lancerMenu();
    }
}
