import java.sql.*;
import java.util.Scanner;

public class InterfaceAdmin {
    String url = "jdbc:postgresql://localhost:****/******"; // TODO : url connection
    private final Scanner scanner = new Scanner(System.in);
    Connection conn = null;
    private PreparedStatement listeArtistes;
    private PreparedStatement listeEvents;

    public InterfaceAdmin() {
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
            listeArtistes = conn.prepareStatement("SELECT nom, nbs_tickets FROM gestion_evenements.artistesParNbrePlaces");
            listeEvents = conn.prepareStatement("SELECT * FROM gestion_evenements.events_festival WHERE date_evenement BETWEEN ? AND ?");
        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    public void lancerMenu() {
        int choix;
        System.out.println("\n********************************************************** BIENVENUE DANS L'INTERFACE ADMINISTRATEUR ! *****************************************************************\n");
        do {
            System.out.println("1 => Voir les artistes et leur nombre de places vendues");
            System.out.println("2 => Voir les évènements dans une période spécifique\n");

            System.out.print("Veuillez introduire votre choix : ");
            String tmp_choix = scanner.next();
            scanner.nextLine();

            while (choixMenu(tmp_choix)) {
                System.out.print("Votre choix n'est pas un chiffre compris entre 1 et 2\nVeuillez introduire votre choix : ");
                tmp_choix = scanner.next();
                scanner.nextLine();
            }
            choix = Integer.parseInt(tmp_choix);

            switch (choix) {
                case 1:
                    listeArtistes();
                    break;
                case 2:
                    listeEvents();
                    break;
            }
        } while (choix >= 1 && choix <= 2);

        System.out.println("Fin du programme");
        close();
    }

    private void listeArtistes() {
        try (ResultSet rs = listeArtistes.executeQuery()) {
            while (rs.next()) {
                System.out.println("\nArtiste : " + rs.getString(1));
                System.out.println("Nombre de places réservées : " + rs.getString(2));
            }
            System.out.println();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    private boolean afficherListeEvents(String dateDebut, String dateFin) {
        try {
            try {
                Date debut = Date.valueOf(dateDebut);
                Date fin = Date.valueOf(dateFin);

                if (debut.after(fin)) {
                    listeEvents.setDate(1, fin);
                    listeEvents.setDate(2, debut);
                } else {
                    listeEvents.setDate(1, debut);
                    listeEvents.setDate(2, fin);
                }

                listeEvents.executeQuery();
                return true;
            } catch (IllegalArgumentException e) {
                System.out.println("\nLe format YYYY-MM-DD n'a pas été respecté ou les dates sont invalides.\n");
                return false;
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return false;
        }
    }

    private void listeEvents() {
        String dateDebut;
        String dateFin;

        do {
            System.out.print("Entrée la date de début : ");
            dateDebut = scanner.next();
            System.out.print("Entrée la date de fin : ");
            dateFin = scanner.next();

        } while (!afficherListeEvents(dateDebut, dateFin));

        try (ResultSet rs = listeEvents.executeQuery()) {
            while (rs.next()) {
                System.out.println("\nNom de l'évènement : " + rs.getString(2));
                System.out.println("Date : " + rs.getString(1));
                System.out.println("Salle : " + rs.getString(4));
                System.out.println("Festival : " + rs.getString(6));
                System.out.println("Nombre de tickets déjà vendus : " + rs.getString(5));
            }
            System.out.println();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
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

    private void close() {
        try {
            conn.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    public static void main(String[] args) {
        InterfaceAdmin interfaceAdmin = new InterfaceAdmin();
        interfaceAdmin.lancerMenu();
    }
}
