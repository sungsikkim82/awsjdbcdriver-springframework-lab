package org.support.engineering.awsjdbcdriverspringframeworklab.repository;

import org.springframework.data.repository.CrudRepository;
import org.support.engineering.awsjdbcdriverspringframeworklab.entity.User;

public interface UserRepository extends CrudRepository<User, Long> {
}
