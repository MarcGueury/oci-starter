
package me.opc.mp.database;

import java.util.List;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

/**
 * This class implements a REST endpoint to retrieve Pokemon types.
 *
 * <ul>
 * <li>GET /type: Retrieve list of all pokemon types</li>
 * </ul>
 *
 * Pokemon, and Pokemon character names are trademarks of Nintendo.
 */
@Path("dept")
public class DeptResource {

    @PersistenceContext(unitName = "pu1")
    private EntityManager entityManager;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Dept> getDept() {
        return entityManager.createNamedQuery("getDept", Dept.class).getResultList();
    }
}
